# app/models/upload_workflow/bulk.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Bulk < UploadWorkflow
  # Initial declaration to establish the namespace.
end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

module UploadWorkflow::Bulk::Errors
  include UploadWorkflow::Errors
end

module UploadWorkflow::Bulk::Properties
  include UploadWorkflow::Properties
  include UploadWorkflow::Bulk::Errors
end

# =============================================================================
# :section: Core
# =============================================================================

public

# Upload mechanisms specific to bulk-upload workflows.
#
module UploadWorkflow::Bulk::External

  include UploadWorkflow::External
  include UploadWorkflow::Bulk::Properties
  include UploadWorkflow::Bulk::Events

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Bulk uploads.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [Boolean]            index   If *false*, do not update index.
  # @param [Boolean]            atomic  If *false*, do not stop on failure.
  # @param [Hash]               opt     Passed to #bulk_upload_file via
  #                                       #batch_upload_operation.
  #
  # @return [(Array,Array)]   Succeeded records and failed item messages.
  #
  # @see #bulk_upload_file
  # @see #bulk_db_insert
  # @see UploadWorkflow::External#add_to_index
  #
  # Compare with:
  # @see UploadWorkflow::External#upload_create
  #
  #--
  # noinspection DuplicatedCode
  #++
  def bulk_upload_create(entries, index: true, atomic: true, **opt)
    __debug_items("UPLOAD WF #{__method__}", binding)

    # Batch-execute this method unless it is being invoked within a batch.
    if opt[:bulk].blank?
      opt.merge!(index: index, atomic: atomic)
      return batch_upload_operation(__method__, entries, **opt)
    end

    # Translate Hash entries into Upload record instances and all related files
    # to storage.
    records, failed = bulk_upload_file(entries, **opt)
    return [], failed if atomic && failed.present? || records.blank?

    # Save the records to the database (and send associated files to storage).
    records, failed = bulk_db_insert(records, atomic: atomic)
    return [], failed if atomic && failed.present? || records.blank?

    # Include the new submissions in the index.
    return records, failed unless index && records.present?
    succeeded, rejected, _ = add_to_index(*records, atomic: atomic)
    return succeeded, (failed + rejected)
  end

  # Bulk modifications.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [Boolean]            index   If *false*, do not update index.
  # @param [Boolean]            atomic  If *false*, do not stop on failure.
  # @param [Hash]               opt     Passed to #bulk_upload_file via
  #                                       #batch_upload_operation.
  #
  # @return [(Array,Array)]   Succeeded records and failed item messages.
  #
  # @see #bulk_upload_file
  # @see #bulk_db_update
  # @see #update_in_index
  #
  # Compare with:
  # @see UploadWorkflow::External#upload_edit
  #
  #--
  # noinspection DuplicatedCode
  #++
  def bulk_upload_edit(entries, index: true, atomic: true, **opt)
    __debug_items("UPLOAD WF #{__method__}", binding)

    # Batch-execute this method unless it is being invoked within a batch.
    if opt[:bulk].blank?
      opt.merge!(index: index, atomic: atomic)
      return batch_upload_operation(__method__, entries, **opt)
    end

    # Translate hash entries into Upload record instances and ensure that all
    # related files are in storage.
    records, failed = bulk_upload_file(entries, **opt)
    return [], failed if atomic && failed.present? || records.blank?

    # Update records in the database.
    records, failed = bulk_db_update(records, atomic: atomic)
    return [], failed if atomic && failed.present? || records.blank?

    # Update the index with the modified submissions.
    return records, failed unless index && records.present?
    succeeded, rejected, _ = update_in_index(*records, atomic: atomic)
    return succeeded, (failed + rejected)
  end

  # Bulk removal.
  #
  # @param [Array<String,Integer,Hash,Upload>] id_specs
  # @param [Boolean] index            If *false*, do not update index.
  # @param [Boolean] atomic           If *false*, do not stop on failure.
  # @param [Hash]    opt              Passed to #batch_upload_remove.
  #
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  # == Implementation Notes
  # For the time being, this does not use #bulk_db_delete because the speed
  # advantage of using a single SQL DELETE statement probably overwhelmed by
  # the need to fetch each record in order to call :delete_file on it.
  #
  def bulk_upload_remove(id_specs, index: true, atomic: true, **opt)
    __debug_items("UPLOAD WF #{__method__}", binding)
    batch_upload_remove(id_specs, index: index, atomic: atomic, **opt)
  end

  # ===========================================================================
  # :section: Storage
  # ===========================================================================

  protected

  # Prepare entries for bulk insert/upsert to the database by ensuring that all
  # associated files have been uploaded and moved into storage.
  #
  # Failures of individual uploads are logged; the method will return with only
  # the successful uploads.
  #
  # @param [Array<Hash,Upload>] entries
  # @param [String]             base_url
  # @param [User, String]       user
  # @param [Integer]            limit     Only the first *limit* records.
  # @param [Hash]               opt       Passed to #new_record except for:
  #
  # @option opt [Hash] :bulk              Info to support bulk upload
  #                                         reporting and error messages.
  #
  # @return [(Array,Array)]   Succeeded records and failed item messages.
  #
  # @see UploadWorkflow::External#new_record
  # @see Upload#promote_file
  #
  def bulk_upload_file(entries, base_url: nil, user: nil, limit: nil, **opt)
    opt[:base_url]   = base_url || Upload::BULK_BASE_URL
    opt[:user_id]    = User.find_id(user || Upload::BULK_USER)
    opt[:importer] ||= Import::IaBulk # TODO: ?

    # Honor :limit if given.
    limit   = limit.presence.to_i
    entries = Array.wrap(entries).compact_blank
    entries = entries.take(limit) if limit.positive?

    # Determine data properties for reporting purposes.
    properties  = opt.delete(:bulk)
    total_count = properties&.dig(:total)        || entries.size
    counter     = properties&.dig(:window, :min) || 0

    failed  = []
    records =
      entries.map { |entry|
        throttle(counter)
        counter += 1
        Log.info do
          msg = "#{__method__} [#{counter} of #{total_count}]:"
          msg += " #{entry}" if entry.is_a?(Upload)
          msg
        end
        begin
          entry = new_record(entry.merge(opt)) unless entry.is_a?(Upload)
          entry.promote_file
          entry
        rescue => error
          failed << db_failed_format(entry, error.message, counter)
          Log.error { "#{__method__}: #{error.class}: #{error.message}" }
          re_raise_if_internal_exception(error)
        end
      }.compact
    return records, failed
  end

  # ===========================================================================
  # :section: Database
  # ===========================================================================

  public

  # Bulk create database records.
  #
  # @param [Array<Upload>] records
  # @param [Hash]          opt        Passed to #bulk_db_operation.
  #
  # @return [(Array,Array)]   Succeeded records and failed item messages.
  #
  # @see ActiveRecord::Persistence::ClassMethods#insert_all
  #
  def bulk_db_insert(records, **opt)
    succeeded, failed = bulk_db_operation(:insert_all, records, **opt)
    if succeeded.present?
      ids_sids  = succeeded.map { |r| identifiers(r).presence || r }
      succeeded = collect_records(*ids_sids).first
    end
    if failed.present?
      failed.each(&:delete_file)
      db_failed_format!(failed, 'Not added') # TODO: I18n
    end
    return succeeded, failed
  end

  # Bulk modify database records.
  #
  # @param [Array<Upload>] records
  # @param [Hash]          opt        Passed to #bulk_db_operation.
  #
  # @return [(Array,Array)]   Succeeded records and failed item messages.
  #
  # @see ActiveRecord::Persistence::ClassMethods#upsert_all
  #
  def bulk_db_update(records, **opt)
    succeeded, failed = bulk_db_operation(:upsert_all, records, **opt)
    if failed.present?
      # TODO: removal of newly-added files associated with failed records.
      db_failed_format!(failed, 'Not updated') # TODO: I18n
    end
    return succeeded, failed
  end

  # Bulk delete database records.
  #
  # @param [Array<String>] ids
  # @param [Boolean]       atomic     If *false*, allow partial changes.
  #
  # @return [(Array,Array)]   Succeeded records and failed item messages.
  #
  # @see ActiveRecord::Persistence::ClassMethods#delete
  #
  # @deprecated Use UploadWorkflow::External#upload_remove instead.
  #
  # == Usage Notes
  # This method should be avoided in favor of #upload_remove because use of
  # SQL DELETE on multiple record IDs does nothing for removing the associated
  # files in cloud storage.  Although code has been added to attempt to handle
  # this issue, it's untested.
  #
  def bulk_db_delete(ids, atomic: true, **)
    __debug_items("UPLOAD WF #{__method__}", binding)
    db_action = ->() {
      find_records(*ids, force: false).each(&:delete_file)
      Upload.delete(ids)
    }
    success = false
    result =
      if atomic
        Upload.transaction do
          db_action.call.tap do |count|
            unless count == ids.size
              msg = [__method__]
              msg << 'atomic delete failed'
              msg << "#{count} of #{ids.size} deleted"
              raise ActiveRecord::Rollback, msg.join(': ')
            end
          end
        end
      else
        db_action.call
      end
    success = (result == ids.size)
  rescue => error
    Log.error { "#{__method__}: #{error.class}: #{error.message}" }
    raise error
  ensure
    # noinspection RubyScope
    if success
      return ids, []
    else
      return [], db_failed_format!(ids, 'Not removed') # TODO: I18n
    end
  end

  # ===========================================================================
  # :section: Database
  # ===========================================================================

  protected

  # Break sets of records into chunks of this size.
  #
  # @type [Integer]
  #
  BULK_DB_BATCH_SIZE = ENV.fetch('BULK_DB_BATCH_SIZE', BATCH_SIZE).to_i

  # Bulk database operation.
  #
  # If the number of records exceeds *size* then it is broken up into batches
  # unless explicitly avoided.
  #
  # @param [Symbol]        op  Upload class method.
  # @param [Array<Upload>] records
  # @param [Boolean]       atomic     If *false*, allow partial changes.
  # @param [Integer]       size       Default: #BULK_DB_BATCH_SIZE
  #
  # @return [(Array<Upload>,Array<Upload>)]   Succeeded/failed records.
  #
  # @see #bulk_db_operation_batches
  # @see #bulk_db_operation_batch
  #
  # == Implementation Notes
  # For currently undiscovered reasons, the MySQL instance on AWS will be
  # overwhelmed if the "VALUE" portion of the "INSERT INTO" statement is very
  # large.  Breaking the data into bite-size chunks is currently the only
  # available work-around.
  #
  def bulk_db_operation(op, records, atomic: true, size: nil, **)
    __debug_items((dbg = "UPLOAD WF #{__method__}"), binding)
    size ||= BULK_DB_BATCH_SIZE
    succeeded, failed =
      if records.size <= size
        bulk_db_operation_batch(op, records)
      elsif !atomic
        bulk_db_operation_batches(op, records, size: size)
      else
        Upload.transaction do
          bulk_db_operation_batches(op, records, size: size)
        end
      end
    if succeeded.nil?
      __debug_line(dbg) { 'TRANSACTION ROLLED BACK' }
      return [], records
    else
      __debug_line(dbg) { { succeeded: succeeded.size, failed: failed.size } }
      return succeeded, failed
    end
  end

  # Invoke a database operation multiple times to process all of the given
  # records with manageably-sized SQL commands.
  #
  # @param [Symbol]        op         Upload class method.
  # @param [Array<Upload>] records
  # @param [Integer]       size
  #
  # @return [(Array<Upload>,Array<Upload>)]   Succeeded/failed records.
  #
  def bulk_db_operation_batches(op, records, size: BULK_DB_BATCH_SIZE)
    succeeded = []
    failed    = []
    counter   = 0
    records.each_slice(size) do |batch|
      throttle(counter)
      min  = size * counter
      max  = (size * (counter += 1)) - 1
      s, f = bulk_db_operation_batch(op, batch, from: min, to: max)
      succeeded += s
      failed    += f
    end
    return succeeded, failed
  end

  # Invoke a database operation.
  #
  # @param [Symbol]        op         Upload class method.
  # @param [Array<Upload>] records
  # @param [Integer]       from       For logging; default: 0.
  # @param [Integer]       to         For logging; default: tail of *records*.
  #
  # @return [(Array<Upload>,Array<Upload>)]   Succeeded/failed records.
  #
  # == Implementation Notes
  # The 'failed' portion of the method return will always be empty if using
  # MySQL because ActiveRecord::Result for bulk operations does not contain
  # useful information.
  #
  def bulk_db_operation_batch(op, records, from: nil, to: nil)
    from ||= 0
    to   ||= records.size - 1
    __debug(dbg = "UPLOAD WF #{op} | records #{from} to #{to}")
    result = Upload.send(op, records.map(&:attributes))
    if result.columns.blank? || (result.length == records.size)
      __debug_line(dbg) { 'QUALIFIED SUCCESS' }
      return records, []
    else
      updated = result.to_a.flat_map { |hash| identifiers(hash) }.compact
      __debug_line(dbg) { "UPDATED #{updated}" }
      records.partition { |record| updated.include?(identifier(record)) }
    end
  end

  # ===========================================================================
  # :section: Database
  # ===========================================================================

  protected

  # Replace a list of failed database items with error entries.
  #
  # @param [Array<Upload,Hash,String>] items
  # @param [String]                    message
  # @param [Integer]                   position
  #
  # @return [Array<ErrorEntry>]
  #
  def db_failed_format!(items, message, position = 0)
    # noinspection RubyYardReturnMatch
    items.map! do |item|
      db_failed_format(item, message, (position += 1))
    end
  end

  # Create an error entry for a single failed database item.
  #
  # @param [Upload, Hash, String] item
  # @param [String]               message
  # @param [Integer]              position
  #
  # @return [ErrorEntry]
  #
  def db_failed_format(item, message, position)
    label = make_label(item, default: "Item #{position}") # TODO: I18n
    ErrorEntry.new(label, message)
  end

  # ===========================================================================
  # :section: Index ingest
  # ===========================================================================

  public

  # Add the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload>] items
  # @param [Boolean]       atomic
  # @param [Hash]          opt        Passed to #batch_upload_operation.
  #
  # @raise [Api::Error] @see IngestService::Request::Records#put_records
  #
  # @return [(Array,Array,Array)]     Succeeded records, failed item messages,
  #                                     and records to roll back.
  #
  def bulk_add_to_index(*items, atomic: true, **opt)
    __debug_items("UPLOAD WF #{__method__}", binding)
    batch_upload_operation(:add_to_index, items, atomic: atomic, **opt)
  end

  # Add/modify the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload>] items
  # @param [Hash]          opt        Passed to #batch_upload_operation.
  #
  # @raise [Api::Error] @see IngestService::Request::Records#put_records
  #
  # @return [(Array,Array,Array)]     Succeeded records, failed item messages,
  #                                     and records to roll back.
  #
  def bulk_update_in_index(*items, **opt)
    __debug_items("UPLOAD WF #{__method__}", binding)
    batch_upload_operation(:update_in_index, items, **opt)
  end

  # Remove the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload, String>] items
  # @param [Hash]                  opt    Passed to #batch_upload_operation.
  #
  # @raise [Api::Error] @see IngestService::Request::Records#delete_records
  #
  # @return [(Array,Array)]   Succeeded items and failed item messages.
  #
  def bulk_remove_from_index(*items, **opt)
    __debug_items("UPLOAD WF #{__method__}", binding)
    batch_upload_operation(:remove_from_index, items, **opt)
  end

end

# Workflow execution status information specific to bulk-upload workflows.
#
module UploadWorkflow::Bulk::Data

  include UploadWorkflow::Data
  include UploadWorkflow::Bulk::External

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Items to upsert/delete.
  #
  # @return [Array<Upload,String,Array>]
  #
  attr_reader :entries

  # The bulk operation control file supplied by the user.
  #
  # @return [String, nil]
  #
  attr_reader :control_file

  # ===========================================================================
  # :section: Workflow::Base::Data overrides
  # ===========================================================================

  public

  # The characteristic "return value" of the workflow after an event has been
  # registered.
  #
  # For bulk upload, this is always the list of successful items.
  #
  # @return [Array<Upload,String>]
  #
  def results
    @results ||= succeeded
  end

  # set_data
  #
  # @param [Array<Upload,String,Array>] data
  #
  # @return [Array<Upload,String,Array>]
  #
  def set_data(data)
    data = super
    @entries = Array.wrap(data)
  end

  alias_method :set_entries, :set_data

  # ===========================================================================
  # :section: Workflow::Base::Data overrides
  # ===========================================================================

  protected

  # reset_status
  #
  # @return [void]
  #
  def reset_status(*)
    super
    @control_file = nil
  end

  # ===========================================================================
  # :section: Workflow::Base::Data overrides
  # ===========================================================================

  public

  # Indicate whether entries have been assigned.
  #
  def empty?
    super && entries.blank?
  end

  # Indicate whether the item is valid.
  #
  def complete?
    super && control_file.present?
  end

  # Indicate whether submission can happen.
  #
  def ready?
    super || complete?
  end

end

# New and overridden action methods specific to bulk-upload workflows.
#
module UploadWorkflow::Bulk::Actions

  include UploadWorkflow::Actions
  include UploadWorkflow::Bulk::Data
  include UploadWorkflow::Bulk::Roles

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Set the workflow phase and state for all Upload records associated with
  # the bulk action.
  #
  # @param [Array<Upload>]       items    Default: `#succeeded`.
  # @param [String, Symbol, nil] state    Default: `#current_state`.
  #
  # @return [void]
  #
  def wf_set_records_state(*items, state: nil)
    items = succeeded if items.blank?
    items.each do |item|
      next unless item.is_a?(Upload)
      state ||= current_state
      item.set_phase(workflow_phase)
      item.set_state(state, workflow_column)
    end
  end

end

module UploadWorkflow::Bulk::Simulation

  include UploadWorkflow::Simulation

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  attr_reader :submission # TODO: delete
  attr_reader :record     # TODO: delete

end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Bulk::Events
  include UploadWorkflow::Events
  include UploadWorkflow::Bulk::Simulation
end

# Overridden state transition methods specific to bulk-upload workflows.
#
module UploadWorkflow::Bulk::States

  include UploadWorkflow::States
  include UploadWorkflow::Bulk::Events
  include UploadWorkflow::Bulk::Actions

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Submission
  # ===========================================================================

  public

  # Upon entering the :staging state:
  #
  # The submission request (submitted file plus generated request form) has
  # been added to the staging area.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_staging_entry(state, event, *event_args)
    super

    # Determine whether this is destined for a member repository.
    if simulating
      __debug_sim("[emma_items: #{submission.emma_item}]")
      emma_items = submission.emma_item
    else
      emma_items = true # TODO: ???
    end

    unless simulating
      wf_finalize_submission(*event_args)
    end

    # TODO: simulation - remove
    if emma_items
      __debug_sim('SYSTEM determines this is an EMMA-native submission.')
    else
      __debug_sim('SYSTEM moves the submission into the repo staging area.')
    end

    # Automatically transition to the next state based on submission status.
    if emma_items
      index!   # NOTE: => :indexing
    else
      advance! # NOTE: => :unretrieved
    end
    self
  end

  # Upon entering the :unretrieved state:
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_unretrieved_entry(state, event, *event_args)
    super

    if simulating

      task = RetrievalTask

      unless event == :timeout
        __debug_sim("Start #{task} to check for the submission.")
        task.start
      end

      if task.check
        __debug_sim("The #{task} is checking...")
        timeout! # NOTE: => :unretrieved

      elsif task.success
        __debug_sim("The #{task} has detected the submission.")
        advance! # NOTE: => :retrieved

      else
        __debug_sim("The #{task} still has NOT detected the submission.")
        __debug_sim('SYSTEM notifies the user of submission status.')
        __debug_sim('SYSTEM notifies an agent of the member repository.')
        if task.restart
          __debug_sim("The #{task} is restarting.")
          timeout! # NOTE: => :unretrieved
        else
          __debug_sim("The #{task} is terminated.")
          fail!    # NOTE: => :failed
        end
      end

    end

    unless simulating
      advance! # NOTE: => :retrieved
    end

    self
  end

  # Upon entering the :retrieved state:
  #
  # The submission request has been retrieved by the member repository and
  # removed from the staging area.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_retrieved_entry(state, event, *event_args)
    super

    __debug_sim('The submission has been received by the member repository.')
    __debug_sim('SYSTEM ensures the staging area is consistent.')

    advance! # NOTE: => :indexing
    self
  end

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Finalization
  # ===========================================================================

  public

  # Upon entering the :indexing state:
  #
  # For an EMMA-native submission, the item is being added to the index.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_indexing_entry(state, event, *event_args)
    super
    wf_set_records_state

    if simulating

      task = IndexTask

      unless event == :timeout
        __debug_sim("Start #{task} to check for the submission.")
        task.start
      end

      if task.check
        __debug_sim("The #{task} is checking...")
        timeout! # NOTE: => :indexing

      elsif task.success
        __debug_sim("The #{task} has detected the submission.")
        advance! # NOTE: => :indexed

      else
        __debug_sim("The #{task} still has NOT detected the submission.")
        __debug_sim('SYSTEM notifies the user of submission status.')
        __debug_sim('SYSTEM notifies an agent of the member repository.')
        if task.restart
          __debug_sim("The #{task} is restarting.")
          timeout! # NOTE: => :indexing
        else
          __debug_sim("The #{task} is terminated.")
          fail!    # NOTE: => :failed
        end
      end

    end

    unless simulating
      wf_index_update(*event_args)
      if ready?
        advance! # NOTE: => :indexed
      else
        fail!    # NOTE: => :failed
      end
    end

    self
  end

  # Upon entering the :indexed state:
  #
  # The submission is complete and present in the EMMA Unified Index.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_indexed_entry(state, event, *event_args)
    super
    wf_set_records_state

    __debug_sim('SYSTEM notifies the user that the submission is complete.')

    advance! # NOTE: => :completed
    self
  end

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Terminal
  # ===========================================================================

  public

  # Upon entering the :failed state:
  #
  # The system is terminating the workflow.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_failed_entry(state, event, *event_args)
    super
    wf_set_records_state

    __debug_sim("[prev_state == #{prev_state.inspect}]")
    __debug_sim('SYSTEM has terminated the workflow.')
    __debug_sim('Associated data will persist until this entry is pruned.')

    self
  end

  # Upon entering the :canceled state:
  #
  # The user is choosing to terminate the workflow.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_canceled_entry(state, event, *event_args)
    super
    wf_set_records_state

    __debug_sim("[prev_state == #{prev_state.inspect}]")
    __debug_sim('USER has terminated the workflow.')
    __debug_sim('Associated data will persist until this entry is pruned.')

    self
  end

  # Upon entering the :completed state:
  #
  # The user is choosing to terminate the workflow.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_completed_entry(state, event, *event_args)
    super
    wf_set_records_state

    __debug_sim("[prev_state == #{prev_state.inspect}]")
    __debug_sim('The submission has been completed successfully.')

    halt unless DEBUG_WORKFLOW
    self
  end

  # ===========================================================================
  # :section: UploadWorkflow::States overrides - Pseudo
  # ===========================================================================

  public

  # Upon entering the :resuming state:
  #
  # Pseudo-state indicating the previous workflow state.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_resuming_entry(state, event, *event_args)
    super
    persist_workflow_state(prev_state)
    __debug_entry(current_state)
    self
  end

  # Upon entering the :purged state:
  #
  # All data associated with the submission is being eliminated.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_purged_entry(state, event, *event_args)
    super

    __debug_sim('The submission entry is being purged.')

    __debug_sim('Shrine cache item is being removed from AWS S3.')
    # TODO: remove Shrine cache item from AWS S3.

    __debug_sim('Database entry is being removed.')
    # TODO: delete 'upload' table record, OR mark as purged:
    #set_workflow_phase(:purge) # TODO: what record?

    halt
    self
  end

end

# =============================================================================
# :section: Base for bulk upload workflows
# =============================================================================

public

if UploadWorkflow::Bulk::SIMULATION
  require_relative '../../../lib/sim/models/upload_workflow/bulk'
end

# Base class for bulk-upload workflows.
#
class UploadWorkflow::Bulk < UploadWorkflow

  include UploadWorkflow::Bulk::Events
  include UploadWorkflow::Bulk::States
  include UploadWorkflow::Bulk::Transitions

  # ===========================================================================
  # :section: Workflow::Base overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Array<Hash,Upload>] data
  # @param [Hash]               opt   Passed to #initialize_state
  #
  def initialize(data, **opt)
    __debug("UPLOAD WF initialize UploadWorkflow::Bulk | opt[:start_state] = #{opt[:start_state].inspect} | opt[:init_event] = #{opt[:init_event].inspect} | data = #{data.class}")
    @control_file = opt[:control]
    data = set_entries(data)
    super(data, **opt)
  end

end

__loading_end(__FILE__)
