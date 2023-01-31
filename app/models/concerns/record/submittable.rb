# app/models/concerns/record/submittable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# TODO: workflow logic
#
# NOTE: This is basically UploadWorkflow::External but without any of the
#   Workflow module-specific stuff.
#
# NOTE: A big problem here may be the built-in assumption that there's only one
#   type of record to deal with...
#
module Record::Submittable

  extend ActiveSupport::Concern

  include Record
  include Record::EmmaIdentification
  include Record::Exceptions
  include Record::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module RecordMethods

    include Record::Submittable

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the item represents an EMMA repository entry (as opposed
    # to a member repository entry).
    #
    # @param [Model, String, Any] item
    #
    # @see Record::EmmaIdentification#valid_sid?
    # @see Record::EmmaIdentification#emma_native?
    #
    def emma_item?(item)                                                        # NOTE: from UploadWorkflow::External
      valid_sid?(item) || emma_native?(item)
    end

    # Indicate whether the item does not represent an existing EMMA entry.
    #
    # @param [Model, String, Any] item
    #
    def incomplete?(item)                                                       # NOTE: from UploadWorkflow::External
      if item.is_a?(Entry)
        item.current_phase&.new_submission?
      else
        # noinspection RailsParamDefResolve
        item.try(:new_submission?)
      end || false
    end

    # Create a new free-standing (un-persisted) record instance.
    #
    # @param [Hash, Model, nil] data  Passed to record class initializer.
    #
    # @return [Model]
    #
    # @see #add_title_prefix
    #
    def new_record(data = nil)                                                  # NOTE: from UploadWorkflow::External
      __debug_items("ENTRY WF #{__method__}", binding)
      record_class.new(data).tap do |record|
        prefix = model_options.title_prefix
        add_title_prefix(record, prefix: prefix) if prefix
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # If a prefix was specified, apply it to the record's title.
    #
    # @param [Model]  record
    # @param [String] prefix
    #
    # @return [void]
    #
    def add_title_prefix(record, prefix:)                                       # NOTE: from UploadWorkflow::External
      return unless prefix.present?
      return unless record.respond_to?(:emma_metadata)
      return unless (title = record.emma_metadata[:dc_title])
      prefix = "#{prefix} - " unless prefix.match?(/[[:punct:]]\s*$/)
      prefix = "#{prefix} "   unless prefix.end_with?(' ')
      return if title.start_with?(prefix)
      record.modify_emma_data(dc_title: "#{prefix}#{title}")
    end

  end

  module DatabaseMethods

    include Record::Submittable
    include Record::Submittable::RecordMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Add a single record to the database.
    #
    # @param [Model, Hash] data       @see Entry#assign_attributes.
    #
    # @return [ApplicationRecord<Model>]
    #
    def db_insert(data)                                                         # NOTE: from UploadWorkflow::External
      __debug_items("ENTRY WF #{__method__}", binding)
      fault!(data) # See Record::Testing
      record = data.is_a?(record_class) ? data : new_record(data)
      record.save! if record.new_record?
      record
    end

    # Modify a single existing database record.
    #
    # @param [Model, Hash, String] item
    # @param [Hash, nil]           data
    #
    # @raise [Record::StatementInvalid]       If :id/:sid not given.
    # @raise [Record::NotFound]               If *item* was not found.
    # @raise [ActiveRecord::RecordInvalid]    Update failed due to validations.
    # @raise [ActiveRecord::RecordNotSaved]   Update halted due to callbacks.
    #
    # @return [ApplicationRecord<Model>]
    #
    def db_update(item, data = nil)                                             # NOTE: from UploadWorkflow::External
      __debug_items("ENTRY WF #{__method__}", binding)
      item, data = [nil, item] if item.is_a?(Hash)
      # @type [ApplicationRecord<Model>]
      record =
        if item.is_a?(record_class)
          item
        elsif data.blank?
          find_record(item)
        else
          data   = data.dup
          opt    = extract_hash!(data, :no_raise, :meth)
          ids    = extract_hash!(data, :id, :submission_id)
          item ||= ids.values.first
          find_record(item, **opt)
        end
      if data.present?
        record.update!(data)
      elsif record.new_record?
        record.save!
      end
      record
    end

    # Remove a single existing record from the database.
    #
    # @param [Model, Hash, String] item
    #
    # @raise [Record::StatementInvalid]           If :id/:sid not given.
    # @raise [Record::NotFound]                   If *item* was not found.
    # @raise [ActiveRecord::RecordNotDestroyed]   Halted due to callbacks.
    #
    # @return [Any]
    # @return [nil]                   If the record was not found or removed.
    #
    def db_delete(item)                                                         # NOTE: from UploadWorkflow::External
      __debug_items("ENTRY WF #{__method__}", binding)
      find_record(item)&.destroy!
    end

  end

  module IndexIngestMethods

    include Record::Submittable
    include ExecReport::Constants

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include Record::Submittable::SubmissionMethods
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Current Ingest API service instance.
    #
    # @return [IngestService]
    #
    def ingest_api                                                              # NOTE: from UploadWorkflow::External
      IngestService.instance
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # As a convenience for testing, sending to the Federated Search Ingest API  # NOTE: from UploadWorkflow::External
    # can be short-circuited here.  The value should be *false* normally.
    #
    # @type [Boolean]
    #
    DISABLE_UPLOAD_INDEX_UPDATE = true?(ENV['DISABLE_UPLOAD_INDEX_UPDATE'])

    # Patterns indicating errors that should not be reported as indicating a
    # problem that would abort a removal workflow.
    #
    # @type [Array<String,Regexp>]
    #
    IGNORED_REMOVE_ERRORS = [
      'Document not found',
    ].freeze

    # Add the indicated items from the EMMA Unified Index.
    #
    # @param [Array<Entry>] items                                               # TODO: NOTE: by usage must be Entry not Model
    # @param [Boolean]      atomic
    #
    # @raise [Api::Error] @see IngestService::Request::Submissions#put_records
    #
    # @return [Array<(Array,Array,Array)>]  Succeeded records, failed item
    #                                         msgs, and records to roll back.
    #
    def add_to_index(*items, atomic: true, **)                                  # NOTE: from UploadWorkflow::External
      __debug_items("ENTRY WF #{__method__}", binding)
      succeeded, failed, rollback = update_in_index(*items, atomic: atomic)
      if rollback.present?
        if record_class == Entry
          # Any submissions that could not be added to the index will be
          # removed from the database.  The assumption here is that they failed
          # because they were missing information and need to be re-submitted
          # anyway.
          removed, kept = entry_remove(*rollback, atomic: false)
          if removed.present?
            sids = removed.map(&:submission_id)
            Log.info { "#{__method__}: removed: #{sids}" }
            rollback.reject! { |item| sids.include?(item.submission_id) }
          end
          failed += kept if kept.present?
        end
        rollback.each(&:delete_file)
        succeeded = [] if atomic
      end
      return succeeded, failed, rollback
    end

    # Add/modify the indicated items from the EMMA Unified Index.
    #
    # @param [Array<Entry>] items                                               # TODO: NOTE: by usage must be Entry not Model
    # @param [Boolean]      atomic
    #
    # @raise [Api::Error] @see IngestService::Request::Submissions#put_records
    #
    # @return [Array<(Array,Array,Array)>]  Succeeded records, failed item
    #                                         msgs, and records to roll back.
    #
    def update_in_index(*items, atomic: true, **)                               # NOTE: from UploadWorkflow::External
      __debug_items("ENTRY WF #{__method__}", binding)
      items = normalize_index_items(*items, meth: __method__)
      return [], [], [] if items.blank?

      result = ingest_api.put_records(*items)
      succeeded, failed, rollback = process_ingest_errors(result, *items)
      if atomic && failed.present?
        succeeded = []
        rollback  = items
      end
      return succeeded, failed, rollback
    end

    # Remove the indicated items from the EMMA Unified Index.
    #
    # @param [Array<Model,String>] items
    # @param [Boolean]             atomic
    #
    # @raise [Api::Error] @see IngestService::Request::Submissions#delete_records
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    def remove_from_index(*items, atomic: true, **)                             # NOTE: from UploadWorkflow::External
      __debug_items("ENTRY WF #{__method__}", binding)
      # noinspection RubyUnusedLocalVariable
      rec_id = nil
      items.map do |item|
        next item   if item.is_a?(Entry)
        next rec_id if (rec_id = record_id(item))
        Log.warn { "#{__method__}: invalid item #{item.inspect}" }
      end
      items = normalize_index_items(*items, meth: __method__)
      return [], [] if items.blank?

      result = ingest_api.delete_records(*items)
      succeeded, failed, _ =
        process_ingest_errors(result, *items, ignore: IGNORED_REMOVE_ERRORS)
      succeeded = [] if atomic && failed.present?
      return succeeded, failed
    end

    # Override the normal methods if Unified Search update is disabled.

    if DISABLE_UPLOAD_INDEX_UPDATE

      %i[add_to_index update_in_index remove_from_index].each do |m|
        send(:define_method, m) { |*items, **| skip_index_ingest(m, *items) }
      end

      def skip_index_ingest(meth, *items)                                       # NOTE: from UploadWorkflow::External
        __debug { "** SKIPPING ** ENTRY #{meth} | items = #{items.inspect}" }
        return items, []
      end

    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Interpret error message(s) generated by Federated Ingest to determine     # NOTE: from UploadWorkflow::External
    # which item(s) failed.
    #
    # @param [Ingest::Message::Response, Hash{String,Integer=>String}] result
    # @param [Array<Model,String>]                                     items
    # @param [Hash]                                                    opt
    #
    # @return [Array<(Array,Array,Array)>]  Succeeded records, failed item
    #                                         msgs, and records to roll back.
    #
    # @see ExecReport#error_table
    #
    # == Implementation Notes
    # It's not clear whether there would ever be situations where there was a
    # mix of errors by index, errors by submission ID, and/or general errors,
    # but this method was written to be able to cope with the possibility.
    #
    def process_ingest_errors(result, *items, **opt)

      # If there were no errors then indicate that all items succeeded.
      errors = ExecReport[result].error_table(**opt).dup
      return items, [], [] if errors.blank?

      # Otherwise, all items will be assumed to have failed.
      rollback  = items
      sids      = []
      failed    = []
      succeeded = []

      # Errors associated with the position of the item in the request.
      by_index = errors.select { |k| k.is_a?(Integer) }
      if by_index.present?
        errors.except!(*by_index.keys)
        by_index.transform_keys! { |idx| sid_value(items[idx-1]) }
        sids   += by_index.keys
        failed += by_index.map { |sid, msg| FlashPart.new(sid, msg) }
      end

      # Errors associated with item submission ID.
      by_sid = errors.reject { |k| k.start_with?(GENERAL_ERROR_TAG) }
      if by_sid.present?
        errors.except!(*by_sid.keys)
        sids   += by_sid.keys
        failed += by_sid.map { |sid, msg| FlashPart.new(sid, msg) }
      end

      # Remaining (general) errors indicate that there was a problem with the
      # request and that all items have failed.
      if errors.present?
        failed = errors.values.map { |msg| FlashPart.new(msg) } + failed
      elsif sids.present?
        sids = sids.map { |v| sid_value(v) }.uniq
        rollback, succeeded =
          items.partition { |item| sids.include?(sid_value(item)) }
      end

      return succeeded, failed, rollback
    end

    # Return a flatten array of items.
    #
    # @param [Array<Entry, String, Array>] items                                # TODO: NOTE: based on usage Entry not Model
    # @param [Symbol, nil]                 meth   The calling method.
    # @param [Integer]                     max    Maximum number to ingest.
    #
    # @raise [Record::SubmitError]  If item count is too large to be ingested.
    #
    # @return [Array]
    #
    def normalize_index_items(*items, meth: nil, max: INGEST_MAX_SIZE)          # NOTE: from UploadWorkflow::External
      items = items.flatten.compact
      # noinspection RubyMismatchedReturnType
      return items unless items.size > max
      error = "#{meth || __method__}: item count: #{item.size} > #{max}"
      Log.error(error)
      failure(error)
    end

  end

  module MemberRepositoryMethods

    include Record::Submittable
    include Record::Submittable::IndexIngestMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Current AWS API service instance.
    #
    # @return [AwsS3Service]
    #
    def aws_api                                                                 # NOTE: from UploadWorkflow::External
      AwsS3Service.instance
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Failure messages for member repository requests. # TODO: I18n             # NOTE: from UploadWorkflow::External
    #
    # @type [Hash{Symbol=>String}]
    #
    REPO_FAILURE = {
      no_repo:    'No repository given',
      no_items:   'No items given',
      no_create:  'Repository submissions are disabled',
      no_edit:    'Repository modification requests are disabled',
      no_remove:  'Repository removal requests are disabled',
    }.deep_freeze

    # Submit a new item to a member repository.
    #
    # @param [Array<Model>] items
    # @param [Hash]         opt
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    def repository_create(*items, **opt)                                        # NOTE: from UploadWorkflow::External
      succeeded = []
      failed    = []
      if items.blank?
        failed << REPO_FAILURE[:no_items]
      elsif !model_options.repo_create
        failed << REPO_FAILURE[:no_create]
      else
        result = aws_api.creation_request(*items, **opt)
        succeeded, failed = process_aws_errors(result, *items)
      end
      return succeeded, failed
    end

    # Submit a request to a member repository to modify the metadata and/or
    # file of a previously-submitted item.
    #
    # @param [Array<Model>] items
    # @param [Hash]         opt
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    # @note This capability is not yet supported by any member repository.
    #
    def repository_modify(*items, **opt)                                        # NOTE: from UploadWorkflow::External
      succeeded = []
      failed    = []
      if items.blank?
        failed << REPO_FAILURE[:no_items]
      elsif !model_options.repo_edit
        failed << REPO_FAILURE[:no_edit]
      else
        result = aws_api.modification_request(*items, **opt)
        succeeded, failed = process_aws_errors(result, *items)
      end
      return succeeded, failed
    end

    # Request deletion of a prior submission to a member repository.
    #
    # @param [Array<String,Model>] items
    # @param [Hash]                opt
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    # @note This capability is not yet supported by any member repository.
    #
    def repository_remove(*items, **opt)                                        # NOTE: from UploadWorkflow::External
      succeeded = []
      failed    = []
      if items.blank?
        failed << REPO_FAILURE[:no_items]
      elsif opt[:emergency]
        # Emergency override for deleting bogus entries creating during
        # testing/development.
        succeeded, failed = remove_from_index(*items)
      elsif !model_options.repo_remove
        failed << REPO_FAILURE[:no_remove]
      else
        result = aws_api.removal_request(*items, **opt)
        succeeded, failed = process_aws_errors(result, *items)
      end
      return succeeded, failed
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Remove request(s) from a member repository queue.
    #
    # @param [Array<String,Model>] items
    # @param [Hash]                opt
    #
    # @option opt [String] :repo      Required for String items.
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    def repository_dequeue(*items, **opt)                                       # NOTE: from UploadWorkflow::External
      succeeded = []
      failed    = []
      if items.blank?
        failed << REPO_FAILURE[:no_items]
      else
        result = aws_api.dequeue(*items, **opt)
        succeeded, failed = process_aws_errors(result, *items)
      end
      return succeeded, failed
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Interpret error message(s) generated by AWS S3.                           # NOTE: from UploadWorkflow::External
    #
    # @param [AwsS3::Message::Response, Hash{String,Integer=>String}] result
    # @param [Array<String,Model>]                                    items
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    # @see ExecReport#error_table
    #
    def process_aws_errors(result, *items)
      errors = ExecReport[result].error_table
      if errors.blank?
        return items, []
      else
        return [], errors.values.map { |msg| FlashPart.new(msg) }
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Send removal request(s) to member repositories.
    #
    # @param [Hash, Array, Model] items
    # @param [Hash]               opt     Passed to #repository_remove.
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    #--
    # == Variations
    #++
    #
    # @overload repository_removals(requests, **opt)
    #   @param [Hash{Symbol=>Array}]              requests
    #   @param [Hash]                             opt
    #   @return [Array<(Array,Array)>]
    #
    # @overload repository_removals(items, **opt)
    #   @param [Array<String,#emma_recordId,Any>] items
    #   @param [Hash]                             opt
    #   @return [Array<(Array,Array)>]
    #
    def repository_removals(items, **opt)                                       # NOTE: from UploadWorkflow::External
      succeeded = []
      failed    = []
      repository_requests(items).each_pair do |_repo, repo_items|
        repo_items.map! { |item| record_id(item) }
        s, f = repository_remove(*repo_items, **opt)
        succeeded += s
        failed    += f
      end
      return succeeded, failed
    end

    # Remove request(s) from member repository queue(s).
    #
    # @param [Hash, Array] items
    # @param [Hash]        opt        Passed to #repository_remove.
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    #--
    # == Variations
    #++
    #
    # @overload repository_dequeues(requests, **opt)
    #   @param [Hash{Symbol=>Array}]              requests
    #   @param [Hash]                             opt
    #   @return [Array<(Array,Array)>]
    #
    # @overload repository_dequeues(items, **opt)
    #   @param [Array<String,#emma_recordId,Any>] items
    #   @param [Hash]                             opt
    #   @return [Array<(Array,Array)>]
    #
    def repository_dequeues(items, **opt)                                       # NOTE: from UploadWorkflow::External
      succeeded = []
      failed    = []
      repository_requests(items).each_pair do |_repo, repo_items|
        repo_items.map! { |item| record_id(item) }
        s, f = repository_dequeue(*repo_items, **opt)
        succeeded += s
        failed    += f
      end
      return succeeded, failed
    end

    # Transform items into arrays of requests per repository.
    #
    # @param [Hash, Array, Model] items
    # @param [Boolean]            empty_key   If *true*, allow invalid items.
    #
    # @return [Hash{String=>Array<Model>}]  One or more requests per repo.
    #
    #--
    # == Variations
    #++
    #
    # @overload repository_requests(hash, empty_key: false)
    #   @param [Hash{String=>Model,Array<Model>}] hash
    #   @param [Boolean]                          empty_key
    #   @return [Hash{String=>Array<Model>}]
    #
    # @overload repository_requests(requests, empty_key: false)
    #   @param [Array<String,Model,Any>]          requests
    #   @param [Boolean]                          empty_key
    #   @return [Hash{String=>Array<Model>}]
    #
    # @overload repository_requests(request, empty_key: false)
    #   @param [Model]                            request
    #   @param [Boolean]                          empty_key
    #   @return [Hash{String=>Array<Model>}]
    #
    def repository_requests(items, empty_key: false)                            # NOTE: from UploadWorkflow::External
      case items
        when Array, Model
          items  = (items.is_a?(Array) ? items.flatten : [items]).compact_blank
          result = items.group_by { |request| repository_value(request) }
        when Hash
          result = items.transform_values { |requests| Array.wrap(requests) }
        else
          result = {}
          Log.error { "#{__method__}: expected 'items' type: #{items.class}" }
      end
      # noinspection RubyMismatchedReturnType
      empty_key ? result : result.delete_if { |repo, _| repo.blank? }
    end

  end

  module BatchMethods

    include Record::Submittable
    include Record::Submittable::RecordMethods
    include Record::Submittable::MemberRepositoryMethods

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include Record::Submittable::SubmissionMethods
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Bulk removal.
    #
    # @param [Array<String,Integer,Hash,Model>] ids
    # @param [Boolean] index          If *false*, do not update index.
    # @param [Boolean] atomic         If *false*, do not stop on failure.
    # @param [Boolean] force          Default: `#force_delete`.
    # @param [Hash]    opt            Passed to #entry_remove via
    #                                   #batch_entry_operation.
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    def batch_entry_remove(ids, index: true, atomic: true, force: nil, **opt)   # NOTE: from UploadWorkflow::External#batch_upload_remove
      __debug_items("ENTRY WF #{__method__}", binding)
      ids = Array.wrap(ids)

      # Translate items into record instances if possible.
      items, failed = collect_records(*ids, force: force)
      return [], failed if atomic && failed.present? || items.blank?

      # Batching occurs unconditionally in order to ensure that the requested
      # items can be successfully removed from the index.
      opt[:requests] ||= {} if model_options.repo_remove
      opt.merge!(index: index, atomic: atomic, force: force)
      succeeded, failed = batch_entry_operation(:entry_remove, items, **opt)

      # After all batch operations have completed, truncate the database table
      # (i.e., so that the next entry starts with id == 1) if appropriate.
      if model_options.truncate_delete && (ids == %w(*))
        # noinspection RailsParamDefResolve
        if failed.present?
          Log.warn('database not truncated due to the presence of errors')
        elsif !self.class.try(:connection)&.truncate(self.class.table_name)
          Log.warn("cannot truncate '#{self.class.table_name}'")
        end
      end

      # Member repository removal requests that were deferred in #entry_remove
      # are handled now.
      if model_options.repo_remove && opt[:requests].present?
        if atomic && failed.present?
          Log.warn('failure(s) prevented generation of repo removal requests')
        else
          requests = opt.delete(:requests)
          s, f = repository_removals(requests, **opt)
          succeeded += s
          failed    += f
        end
      end

      return succeeded, failed
    end

    # Process *entries* in batches by calling *op* on successive subsets.
    #
    # If *size* is *false* or negative, then *entries* is processed as a single
    # batch.
    #
    # If *size* is *true* or zero or missing, then *entries* is processed in
    # batches of the default #BATCH_SIZE.
    #
    # @param [Symbol]                           op
    # @param [Array<String,Integer,Hash,Model>] items
    # @param [Integer, Boolean]                 size     Default: #BATCH_SIZE.
    # @param [Hash]                             opt
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    def batch_entry_operation(op, items, size: nil, **opt)                      # NOTE: from UploadWorkflow::External#batch_upload_operation
      __debug_items((dbg = "ENTRY WF #{op}"), binding)
      opt[:bulk] ||= { total: items.size }

      # Set batch size for this iteration.
      size = batch_size     if size.nil?
      size = -1             if size.is_a?(FalseClass)
      size =  0             if size.is_a?(TrueClass)
      size = size.to_i
      size = items.size     if size.negative?
      size = BATCH_SIZE     if size.zero?
      size = MAX_BATCH_SIZE if size > MAX_BATCH_SIZE

      succeeded = []
      failed    = []
      counter   = 0
      # noinspection RubyMismatchedArgumentType
      items.each_slice(size) do |batch|
        throttle(counter)
        min = size * counter
        max = (size * (counter += 1)) - 1
        opt[:bulk][:window] = { min: min, max: max }
        __debug_line(dbg) { "records #{min} to #{max}" }
        s, f, _ = send(op, batch, **opt)
        succeeded += s
        failed    += f
      end
      __debug_line(dbg) { { succeeded: succeeded.size, failed: failed.size } }
      return succeeded, failed
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Release the current thread to the scheduler.
    #
    # @param [Integer]       counter    Iteration counter.
    # @param [Integer]       frequency  E.g., '3' means every third iteration.
    # @param [Float,Boolean] pause      Default: `#THROTTLE_PAUSE`.
    #
    # @return [void]
    #
    def throttle(counter, frequency: 1, pause: true)                            # NOTE: from UploadWorkflow::External
      pause = THROTTLE_PAUSE if pause.is_a?(TrueClass)
      return if pause.blank?
      return if counter.zero?
      return if (counter % frequency).nonzero?
      sleep(pause)
    end

  end

  module SubmissionMethods

    include Record::Submittable
    include Record::Submittable::RecordMethods
    include Record::Submittable::DatabaseMethods
    include Record::Submittable::IndexIngestMethods
    include Record::Submittable::MemberRepositoryMethods
    include Record::Submittable::BatchMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Add a new submission to the database, upload its file to storage, and add # TODO: NOTE: currently unused; @see EntryConcern#create_entry
    # a new index entry for it (if explicitly requested).
    #
    # @param [Boolean] index          If *true*, update index.
    # @param [Boolean] atomic         Passed to #add_to_index.
    # @param [Hash]    data           @see Entry#assign_attributes.
    #
    # @return [Array<(Entry,Array>)]  Record instance; zero or more messages.   # TODO: NOTE: Entry not Model
    # @return [Array<(nil,Array)>]    No record; one or more error messages.
    #
    # @see #db_insert
    # @see #add_to_index
    #
    # == Implementation Notes
    # Compare with #bulk_entry_create
    #
    def entry_create(index: nil, atomic: true, **data)                          # NOTE: from UploadWorkflow::External#upload_create
      __debug_items("ENTRY WF #{__method__}", binding)
=begin
      type = record_class                                                       # TODO: NOTE: implicitly "Entry"; probably should make it explicit
=end
      type = Entry

      # Save the record to the database.
      item = db_insert(data)                                                    # NOTE: implicitly @type [Entry] item
      return nil, ["#{type} not created"] unless item.is_a?(type) # TODO: I18n
      return item, item.errors            if item.errors.present?

      # Include the new submission in the index if specified.
      return item, [] unless index
      succeeded, failed, _ = add_to_index(item, atomic: atomic)
      return succeeded.first, failed
    end

    # Update an existing database Entry record and update its associated index  # TODO: NOTE: currently unused; @see EntryConcern#edit_entry
    # entry (if explicitly requested).
    #
    # @param [Boolean] index          If *true*, update index.
    # @param [Boolean] atomic         Passed to #update_in_index.
    # @param [Hash]    data           @see Entry#assign_attributes
    #
    # @return [Array<(Entry,Array>)]  Record instance; zero or more messages.   # TODO: NOTE: Entry not Model
    # @return [Array<(nil,Array)>]    No record; one or more error messages.
    #
    # @see #db_update
    # @see #update_in_index
    #
    # == Implementation Notes
    # Compare with #bulk_entry_edit
    #
    def entry_edit(index: nil, atomic: true, **data)                            # NOTE: from UploadWorkflow::External#upload_edit
      __debug_items("ENTRY WF #{__method__}", binding)
      if (id = data[:id]).blank?
        if (id = data[:submission_id]).blank?
          return nil, ['No identifier provided'] # TODO: I18n
        elsif !valid_sid?(id)
          return nil, ["Invalid EMMA submission ID #{id}"] # TODO: I18n
        end
      end
=begin
      type = record_class                                                       # TODO: NOTE: implicitly "Entry"; probably should make it explicit
=end
      type = Entry

      # Fetch the record and update it in the database.
      item = db_update(data)
      return nil, ["#{type} #{id} not found"] unless item.is_a?(type) # TODO: I18n
      return item, item.errors                if item.errors.present?

      # Update the index with the modified submission if specified.
      return item, [] unless index
      succeeded, failed, _ = update_in_index(*item, atomic: atomic)
      return succeeded.first, failed
    end

    # Remove records from the database and from the index.                      # TODO: NOTE: used by #add_to_index and #batch_entry_remove
    #
    # @param [Array<Entry,String,Array>] items   @see #collect_records          # TODO: NOTE: Entry not Model
    # @param [Boolean]                   index   *false* -> no index update
    # @param [Boolean]                   atomic  *true* == all-or-none
    # @param [Boolean]                   force   Force removal of index entries
    #                                             even if the related database
    #                                             entries do not exist.
    #
    # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
    #
    # @see #remove_from_index
    #
    # == Usage Notes
    # Atomicity of the record removal phase rests on the assumption that any
    # database problem(s) would manifest with the very first destruction
    # attempt.  If a later item fails, the successfully-destroyed items will
    # still be removed from the index.
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def entry_remove(*items, index: nil, atomic: true, force: nil, **opt)       # NOTE: from UploadWorkflow::External#upload_remove
      __debug_items("ENTRY WF #{__method__}", binding)
      type = Entry                                                              # TODO: NOTE: based on usage, Entry is implied

      # Translate items into record instances.
      items, failed = collect_records(*items, force: force, type: type)
      requested = []
      if force
        emergency = opt[:emergency] || model_options.emergency_delete
        # Mark as failed any non-EMMA-items that could not be added to a
        # request for removal of member repository items.
        items, failed =
          items.partition do |item|
            emma_item?(item) || incomplete?(item) ||
              (sid_value(item) if emergency)
          end
        if model_options.repo_remove
          deferred = opt.key?(:requests)
          requests = opt.delete(:requests) || {}
          failed.delete_if do |item|
            next unless (repo = repository_value(item))
            requests[repo] ||= []
            requests[repo] << item
            requested << item
          end
          repository_removals(requests, **opt) unless deferred
        end
      end
      if atomic && failed.present? || items.blank?
        return (items + requested), failed
      end

      # Dequeue member repository creation requests.
      requests = items.select { |item| incomplete?(item) && !emma_item?(item) }
      repository_dequeues(requests, **opt) if requests.present?

      # Remove the records from the database.
      destroyed = []
      retained  = []
      counter   = 0
      items =
        items.map { |item|
          if !item.is_a?(type)
            item                      # Only seen if *force* is *true*.
          elsif db_delete(item)
            throttle(counter)
            counter += 1
            destroyed << item
            item
          elsif atomic && destroyed.blank?
            return [], [item]         # Early return with the problem item.
          else
            retained << item and next # Will not be included in *items*.
          end
        }.compact
      if retained.present?
        Log.warn do
          msg = [__method__]
          msg << 'not atomic' if atomic
          msg << 'items retained in the database that will be de-indexed'
          msg << retained.map { |item| item_label(item) }.join(', ')
          msg.join(': ')
        end
        retained.map! { |item| FlashPart.new(item, 'not removed') } # TODO: I18n
      end

      # Remove the associated entries from the index.
      return items, retained unless index && items.present?
      succeeded, failed = remove_from_index(*items, atomic: atomic)
      return (succeeded + requested), (retained + failed)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def item_label(item)
      Record::Rendering.make_label(item)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include Record::Submittable::SubmissionMethods
    extend  Record::Submittable::SubmissionMethods

  end

end

__loading_end(__FILE__)
