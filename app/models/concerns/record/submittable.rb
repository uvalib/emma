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
    # to an entry subject to the "partner repository workflow").
    #
    # @param [any, nil] item          Model, String
    #
    # @see Record::EmmaIdentification#valid_sid?
    # @see Record::EmmaIdentification#emma_native?
    #
    # @note From UploadWorkflow::External#emma_item?
    #
    def emma_item?(item)
      valid_sid?(item) || emma_native?(item)
    end

    # Indicate whether the item does not represent an existing EMMA entry.
    #
    # @param [any, nil] item          Model, String
    #
    # @note From UploadWorkflow::External#incomplete?
    #
    def incomplete?(item)
=begin # TODO: Upload model replacement
      if item.is_a?(Entry)
        item.current_phase&.new_submission?
      else
        # noinspection RailsParamDefResolve
        item.try(:new_submission?)
      end || false
=end
      item.try(:new_submission?) || false
    end

    # Create a new free-standing (un-persisted) record instance.
    #
    # @param [Hash, Model, nil] data  Passed to record class initializer.
    #
    # @return [Model]
    #
    # @see #add_title_prefix
    #
    # @note From UploadWorkflow::External#new_record
    #
    def new_record(data = nil)
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
    # @note From UploadWorkflow::External#add_title_prefix
    #
    def add_title_prefix(record, prefix:)
      return unless prefix.present?
      return unless record.respond_to?(:emma_metadata)
      return unless (title = record.emma_metadata[:dc_title])
      prefix = "#{prefix} - " unless prefix.match?(/[[:punct:]]\s*$/)
      prefix = "#{prefix} "   unless prefix.end_with?(' ')
      return if title.start_with?(prefix)
      record.modify_emma_data({ dc_title: "#{prefix}#{title}" })
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
    # @param [Model, Hash] data       @see Upload#assign_attributes.
    #
    # @return [ApplicationRecord]
    #
    # @note From UploadWorkflow::External#db_insert
    #
    def db_insert(data)
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
    # @return [ApplicationRecord]
    # @return [nil]                           If `data[:fatal]` is *false*.
    #
    # @note From UploadWorkflow::External#db_update
    #
    def db_update(item, data = nil)
      __debug_items("ENTRY WF #{__method__}", binding)
      item, data = [nil, item] if item.is_a?(Hash)
      record =
        if item.is_a?(record_class)
          item
        elsif data.blank?
          fetch_record(item)
        else
          data   = data.dup
          opt    = data.extract!(:fatal, :meth)
          ids    = data.extract!(:id, :submission_id)
          item ||= ids.values.first
          find_record(item, **opt)
        end
      if data.present?
        record.update!(data)
      elsif record&.new_record?
        record.save!
      end
      # noinspection RubyMismatchedReturnType
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
    # @return [any]
    # @return [nil]                   If the record was not found or removed.
    #
    # @note From UploadWorkflow::External#db_delete
    #
    def db_delete(item)
      __debug_items("ENTRY WF #{__method__}", binding)
      fetch_record(item)&.destroy!
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

    # Current EMMA Unified Ingest API service instance.
    #
    # @return [IngestService]
    #
    # @note From UploadWorkflow::External#ingest_api
    #
    def ingest_api
      IngestService.instance
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # As a convenience for testing, sending to the EMMA Unified Ingest API can
    # be short-circuited here.  The value should be *false* normally.
    #
    # @type [Boolean]
    #
    # @note From UploadWorkflow::External#DISABLE_UPLOAD_INDEX_UPDATE
    #
    DISABLE_UPLOAD_INDEX_UPDATE = true?(ENV_VAR['DISABLE_UPLOAD_INDEX_UPDATE'])

    # Patterns indicating errors that should not be reported as indicating a
    # problem that would abort a removal workflow.
    #
    # @type [Array<String,Regexp>]
    #
    # @note From UploadWorkflow::External#IGNORED_REMOVE_ERRORS
    #
    IGNORED_REMOVE_ERRORS = [
      'Document not found',
    ].freeze

    # Add the indicated items from the EMMA Unified Index.
    #
    # @param [Array<Upload>] items
    # @param [Boolean]       atomic
    #
    # @raise [Api::Error] @see IngestService::Action::Submissions#put_records
    #
    # @return [Array(Array,Array,Array)]  Succeeded records, failed item msgs,
    #                                     and records to roll back.
    #
    # @note From UploadWorkflow::External#add_to_index
    #
    def add_to_index(*items, atomic: true, **)
      __debug_items("ENTRY WF #{__method__}", binding)
      succeeded, failed, rollback = update_in_index(*items, atomic: atomic)
      if rollback.present?
        if record_class == Upload
          # Any submissions that could not be added to the index will be
          # removed from the database.  The assumption here is that they failed
          # because they were missing information and need to be re-submitted
          # anyway.
          removed, kept = entry_remove(*rollback, atomic: false)
          if removed.present?
            sids = removed.map(&:submission_id)
            Log.info { "#{__method__}: removed: #{sids}" }
            rollback.reject! { sids.include?(sid_value(_1)) }
          end
          failed.concat(kept) if kept.present?
        end
        rollback.each(&:delete_file)
        succeeded = [] if atomic
      end
      return succeeded, failed, rollback
    end

    # Add/modify the indicated items from the EMMA Unified Index.
    #
    # @param [Array<Upload>] items
    # @param [Boolean]       atomic
    #
    # @raise [Api::Error] @see IngestService::Action::Submissions#put_records
    #
    # @return [Array(Array,Array,Array)]  Succeeded records, failed item msgs,
    #                                     and records to roll back.
    #
    # @note From UploadWorkflow::External#update_in_index
    #
    def update_in_index(*items, atomic: true, **)
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
    # @raise [Api::Error] @see IngestService::Action::Submissions#delete_records
    #
    # @return [Array(Array,Array)]  Succeeded items and failed item messages.
    #
    # @note From UploadWorkflow::External#remove_from_index
    #
    def remove_from_index(*items, atomic: true, **)
      __debug_items("ENTRY WF #{__method__}", binding)
      # noinspection RubyUnusedLocalVariable
      rec_id = nil
      items.map do |item|
        next item   if item.is_a?(record_class)
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

    # Override the normal methods if EMMA Unified Index update is disabled.

    if DISABLE_UPLOAD_INDEX_UPDATE

      %i[add_to_index update_in_index remove_from_index].each do |m|
        send(:define_method, m) { |*items, **| skip_index_ingest(m, *items) }
      end

      def skip_index_ingest(meth, *items)
        __debug { "** SKIPPING ** ENTRY #{meth} | items = #{items.inspect}" }
        return items, []
      end

    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Interpret error message(s) generated by EMMA Unified Ingest service to
    # determine which item(s) failed.
    #
    # @param [Ingest::Message::Response, Hash{String,Integer=>String}] result
    # @param [Array<Model,String>]                                     items
    # @param [Hash]                                                    opt
    #
    # @return [Array(Array,Array,Array)]  Succeeded records, failed item msgs,
    #                                     and records to roll back.
    #
    # @see ExecReport#error_table
    #
    # @note From UploadWorkflow::External#process_ingest_errors
    #
    # === Implementation Notes
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
      by_index = errors.select { _1.is_a?(Integer) }
      if by_index.present?
        errors.except!(*by_index.keys)
        by_index.transform_keys! { |idx| sid_value(items[idx-1]) }
        sids.concat   by_index.keys
        failed.concat by_index.map { |sid, msg| FlashPart.new(sid, msg) }
      end

      # Errors associated with item submission ID.
      by_sid = errors.reject { _1.start_with?(GENERAL_ERROR_TAG) }
      if by_sid.present?
        errors.except!(*by_sid.keys)
        sids.concat   by_sid.keys
        failed.concat by_sid.map { |sid, msg| FlashPart.new(sid, msg) }
      end

      # Remaining (general) errors indicate that there was a problem with the
      # request and that all items have failed.
      if errors.present?
        failed = errors.values.map { FlashPart.new(_1) } + failed
      elsif sids.present?
        sids = sids.map! { sid_value(_1) }.uniq
        rollback, succeeded = items.partition { sids.include?(sid_value(_1)) }
      end

      return succeeded, failed, rollback
    end

    # Return a flatten array of items.
    #
    # @param [Array<Upload, String, Array>] items
    # @param [Symbol, nil]                  meth    The calling method.
    # @param [Integer]                      max     Maximum number to ingest.
    #
    # @raise [Record::SubmitError]  If item count is too large to be ingested.
    #
    # @return [Array]
    #
    # @note From UploadWorkflow::External#normalize_index_items
    #
    def normalize_index_items(*items, meth: nil, max: INGEST_MAX_SIZE)
      items = items.flatten.compact
      # noinspection RubyMismatchedReturnType
      return items unless items.size > max
      error = "#{meth || __method__}: item count: #{item.size} > #{max}"
      Log.error(error)
      raise_failure(error)
    end

  end

  module PartnerRepositoryMethods

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
    # @note From UploadWorkflow::External#aws_api
    #
    def aws_api
      AwsS3Service.instance
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Failure messages for "partner repository workflow" requests.
    #
    # @type [Hash{Symbol=>String}]
    #
    # @note From UploadWorkflow::External#REPO_FAILURE
    #
    REPO_FAILURE = config_term_section(:record, :failure).deep_freeze

    # Submit a new item through the "partner repository workflow".
    #
    # @param [Array<Model>] items
    # @param [Hash]         opt
    #
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @note From UploadWorkflow::External#repository_create
    #
    def repository_create(*items, **opt)
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

    # Submit a "partner repository workflow" request to modify the metadata
    # and/or file of a previously-submitted item.
    #
    # @param [Array<Model>] items
    # @param [Hash]         opt
    #
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @note This capability is not yet supported by any partner repository.
    #
    # @note From UploadWorkflow::External#repository_modify
    #
    def repository_modify(*items, **opt)
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

    # Request deletion of a prior submission to a partner repository through
    # the "partner repository workflow".
    #
    # @param [Array<String,Model>] items
    # @param [Hash]                opt
    #
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @note This capability is not yet supported by any partner repository.
    #
    # @note From UploadWorkflow::External#repository_remove
    #
    def repository_remove(*items, **opt)
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

    # Remove "partner repository workflow" request(s) from a partner repository
    # queue.
    #
    # @param [Array<String,Model>] items
    # @param [Hash]                opt
    #
    # @option opt [String] :repo      Required for String items.
    #
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @note From UploadWorkflow::External#repository_dequeue
    #
    def repository_dequeue(*items, **opt)
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

    # Interpret error message(s) generated by AWS S3.
    #
    # @param [AwsS3::Message::Response, Hash{String,Integer=>String}] result
    # @param [Array<String,Model>]                                    items
    #
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @see ExecReport#error_table
    #
    # @note From UploadWorkflow::External#process_aws_errors
    #
    def process_aws_errors(result, *items)
      errors = ExecReport[result].error_table
      if errors.blank?
        return items, []
      else
        return [], errors.values.map { FlashPart.new(_1) }
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Send "partner repository workflow" removal request(s) to partner
    # repositories.
    #
    # @param [Hash, Array, Model] items
    # @param [Hash]               opt     Passed to #repository_remove.
    #
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @note From UploadWorkflow::External#repository_removals
    #
    #--
    # === Variations
    #++
    #
    # @overload repository_removals(requests, **opt)
    #   @param [Hash{Symbol=>Array}] requests
    #   @param [Hash]                opt
    #   @return [Array(Array,Array)]
    #
    # @overload repository_removals(items, **opt)
    #   @param [Array]               items
    #   @param [Hash]                opt
    #   @return [Array(Array,Array)]
    #
    def repository_removals(items, **opt)
      succeeded = []
      failed    = []
      repository_requests(items).each_pair do |_repo, repo_items|
        repo_items.map! { record_id(_1) }
        s, f = repository_remove(*repo_items, **opt)
        succeeded.concat(s)
        failed.concat(f)
      end
      return succeeded, failed
    end

    # Remove "partner repository workflow" request(s) from partner repository
    # queue(s).
    #
    # @param [Hash, Array] items
    # @param [Hash]        opt        Passed to #repository_remove.
    #
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    #--
    # === Variations
    #++
    #
    # @overload repository_dequeues(requests, **opt)
    #   @param [Hash{Symbol=>Array}] requests
    #   @param [Hash]                opt
    #   @return [Array(Array,Array)]
    #
    # @overload repository_dequeues(items, **opt)
    #   @param [Array]               items
    #   @param [Hash]                opt
    #   @return [Array(Array,Array)]
    #
    def repository_dequeues(items, **opt)
      succeeded = []
      failed    = []
      repository_requests(items).each_pair do |_repo, repo_items|
        repo_items.map! { record_id(_1) }
        s, f = repository_dequeue(*repo_items, **opt)
        succeeded.concat(s)
        failed.concat(f)
      end
      return succeeded, failed
    end

    # Transform items into arrays of "partner repository workflow" requests per
    # repository.
    #
    # @param [Hash, Array, Model] items
    # @param [Boolean]            empty_key   If *true*, allow invalid items.
    #
    # @return [Hash{String=>Array<Model>}]  One or more requests per repo.
    #
    #--
    # === Variations
    #++
    #
    # @overload repository_requests(hash, empty_key: false)
    #   @param [Hash{String=>Model,Array<Model>}] hash
    #   @param [Boolean]                          empty_key
    #   @return [Hash{String=>Array<Model>}]
    #
    # @overload repository_requests(requests, empty_key: false)
    #   @param [Array<String,Model,any>]          requests
    #   @param [Boolean]                          empty_key
    #   @return [Hash{String=>Array<Model>}]
    #
    # @overload repository_requests(request, empty_key: false)
    #   @param [Model]                            request
    #   @param [Boolean]                          empty_key
    #   @return [Hash{String=>Array<Model>}]
    #
    def repository_requests(items, empty_key: false)
      case items
        when Array, Model
          items  = (items.is_a?(Array) ? items.flatten : [items]).compact_blank
          result = items.group_by { repository_value(_1) }
        when Hash
          result = items.transform_values { Array.wrap(_1) }
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
    include Record::Submittable::PartnerRepositoryMethods

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
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @note From UploadWorkflow::External#batch_upload_remove
    #
    def batch_entry_remove(ids, index: true, atomic: true, force: nil, **opt)
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
      if model_options.truncate_delete && (ids == %w[*])
        # noinspection RailsParamDefResolve
        if failed.present?
          Log.warn('database not truncated due to the presence of errors')
        elsif !self.class.try(:connection)&.truncate(self.class.table_name)
          Log.warn("cannot truncate '#{self.class.table_name}'")
        end
      end

      # Any "partner repository workflow" removal requests that were deferred
      # in #entry_remove are handled now.
      if model_options.repo_remove && opt[:requests].present?
        if atomic && failed.present?
          Log.warn('failure(s) prevented generation of repo removal requests')
        else
          requests = opt.delete(:requests)
          s, f = repository_removals(requests, **opt)
          succeeded.concat(s)
          failed.concat(f)
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
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @note From UploadWorkflow::External#batch_upload_operation
    #
    def batch_entry_operation(op, items, size: nil, **opt)
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
        succeeded.concat(s)
        failed.concat(f)
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
    # @param [Integer]           counter    Iteration counter.
    # @param [Integer]           frequency  E.g., '3' => every third iteration.
    # @param [Float,Boolean,nil] pause      Default: `#BULK_THROTTLE_PAUSE`.
    #
    # @return [void]
    #
    # @note From UploadWorkflow::External#throttle
    #
    def throttle(counter, frequency: 1, pause: true)
      pause = BULK_THROTTLE_PAUSE if pause.is_a?(TrueClass)
      sleep(pause) if pause && counter.nonzero? && (counter % frequency).zero?
    end

  end

  module SubmissionMethods

    include Record::Submittable
    include Record::Submittable::RecordMethods
    include Record::Submittable::DatabaseMethods
    include Record::Submittable::IndexIngestMethods
    include Record::Submittable::PartnerRepositoryMethods
    include Record::Submittable::BatchMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Add a new submission to the database, upload its file to storage, and add
    # a new index entry for it (if explicitly requested).
    #
    # @param [Boolean] index          If *true*, update index.
    # @param [Boolean] atomic         Passed to #add_to_index.
    # @param [Hash]    data           @see Upload#assign_attributes.
    #
    # @return [Array<(Upload,Array>)] Record instance; zero or more messages.
    # @return [Array(nil,Array)]      No record; one or more error messages.
    #
    # @see #db_insert
    # @see #add_to_index
    #
    # @note Currently unused.
    #
    # @note From UploadWorkflow::External#upload_create
    #
    # === Implementation Notes
    # Compare with #bulk_entry_create
    #
    def entry_create(index: nil, atomic: true, **data)
      __debug_items("ENTRY WF #{__method__}", binding)
      type = record_class

      # Save the record to the database.
      item = db_insert(data)
      unless item.is_a?(type)
        return nil, [config_term(:record, :not_created, type: type)]
      end
      return item, item.errors unless item.errors.blank?

      # Include the new submission in the index if specified.
      return item, [] unless index

      # noinspection RubyMismatchedArgumentType
      succeeded, failed, _ = add_to_index(item, atomic: atomic)
      return succeeded.first, failed
    end

    # Update an existing database Upload record and update its associated index
    # entry (if explicitly requested).
    #
    # @param [Boolean] index          If *true*, update index.
    # @param [Boolean] atomic         Passed to #update_in_index.
    # @param [Hash]    data           @see Upload#assign_attributes
    #
    # @return [Array<(Upload,Array>)] Record instance; zero or more messages.
    # @return [Array(nil,Array)]      No record; one or more error messages.
    #
    # @see #db_update
    # @see #update_in_index
    #
    # @note Currently unused.
    #
    # @note From UploadWorkflow::External#upload_edit
    #
    # === Implementation Notes
    # Compare with #bulk_entry_edit
    #
    def entry_edit(index: nil, atomic: true, **data)
      __debug_items("ENTRY WF #{__method__}", binding)
      if (id = data[:id]).blank?
        if (id = data[:submission_id]).blank?
          return nil, [config_term(:record, :no_identifier)]
        elsif !valid_sid?(id)
          return nil, [config_term(:record, :invalid_sid, sid: id)]
        end
      end
      type = record_class

      # Fetch the record and update it in the database.
      item = db_update(data)
      unless item.is_a?(type)
        return nil, [config_term(:record, :not_found, type: type, id: id)]
      end
      return item, item.errors unless item.errors.blank?

      # Update the index with the modified submission if specified.
      return item, [] unless index
      succeeded, failed, _ = update_in_index(*item, atomic: atomic)
      return succeeded.first, failed
    end

    # Remove records from the database and from the index.
    #
    # @param [Array<Upload,String,Array>] items   @see #collect_records
    # @param [Boolean]                    index  *false* -> no index update
    # @param [Boolean]                    atomic *true* == all-or-none
    # @param [Boolean]                    force  Force removal of index entries
    #                                             even if the related database
    #                                             entries do not exist.
    #
    # @return [Array(Array,Array)]    Succeeded items and failed item messages.
    #
    # @see #remove_from_index
    #
    # @note Used by #add_to_index and #batch_entry_remove
    #
    # @note From UploadWorkflow::External#upload_remove
    #
    # === Usage Notes
    # Atomicity of the record removal phase rests on the assumption that any
    # database problem(s) would manifest with the very first destruction
    # attempt.  If a later item fails, the successfully-destroyed items will
    # still be removed from the index.
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def entry_remove(*items, index: nil, atomic: true, force: nil, **opt)
      __debug_items("ENTRY WF #{__method__}", binding)
      type = record_class

      # Translate items into record instances.
      items, failed = collect_records(*items, force: force, type: type)
      requested = []
      if force
        emergency = opt[:emergency] || model_options.emergency_delete
        # Mark as failed any "partner repository workflow" items that could not
        # be added to a request for removal of partner repository items.
        items, failed =
          items.partition do
            emma_item?(_1) || incomplete?(_1) || (sid_value(_1) if emergency)
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

      # Dequeue partner repository creation requests.
      requests = items.select { incomplete?(_1) && !emma_item?(_1) }
      repository_dequeues(requests, **opt) if requests.present?

      # Remove the records from the database.
      destroyed = []
      retained  = []
      removals  = []
      counter   = 0
      items =
        items.map { |item|
          if !item.is_a?(type)
            item                      # Only seen if *force* is *true*.
          elsif db_delete(item)
            throttle(counter)
            counter += 1
            destroyed << item
            removals  << item if item.s3_queue?
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
          msg << retained.map { item_label(_1) }.join(', ')
          msg.join(': ')
        end
        not_removed = config_term(:record, :not_removed)
        retained.map! { FlashPart.new(_1, not_removed) }
      end
      if model_options.repo_remove && removals.present?
        repository_removals(removals, **opt)
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
