# app/models/upload_workflow.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'workflow'

class UploadWorkflow < Workflow::Base

  # Initial declaration to establish the namespace.

  DESTRUCTIVE_TESTING = false

end

# =============================================================================
# :section: Mixins
# =============================================================================

public

# Common elements of workflows associated with the creation of new entries.
#
module UploadWorkflow::Create

  # The 'uploads' table field associated with the workflow state for new
  # entries.
  #
  # @type [Symbol]
  #
  STATE_COLUMN = Upload::PRIMARY_STATE_COLUMN

end

# Common elements of workflows associated with the change of existing entries.
#
module UploadWorkflow::Edit

  # The 'uploads' table field associated with workflow state for workflows
  # involving modification of existing entries.
  #
  # @type [Symbol]
  #
  STATE_COLUMN = Upload::SECONDARY_STATE_COLUMN

end

# Common elements of workflows associated with the removal of existing entries.
#
module UploadWorkflow::Remove

  # The 'uploads' table field associated with workflow state for workflows
  # involving modification of existing entries.
  #
  # @type [Symbol]
  #
  STATE_COLUMN = Upload::SECONDARY_STATE_COLUMN

end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

# Support for handling errors generated within the upload workflow.
#
module UploadWorkflow::Errors

  include Emma::Common
  include Emma::Debug

  # ===========================================================================
  # :section: Modules
  # ===========================================================================

  public

  module RenderMethods

    extend self

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Default label. TODO: I18n                                                 # NOTE: to Record::Rendering
    #
    # @type [String]
    #
    DEFAULT_LABEL = '(missing)'

    # Show the submission ID if it can be determined for the given item(s).
    #
    # @param [Api::Record, Upload, Hash, String, Any] item
    # @param [String]                                 default
    #
    # @return [String]
    #
    def make_label(item, default: DEFAULT_LABEL)                                # NOTE: to Record::Rendering
      file  = (item.filename if item.is_a?(Upload))
      ident = Upload.sid_for(item) || Upload.id_for(item) || default
      ident = "Item #{ident}"      if digits_only?(ident) # TODO: I18n
      ident = "#{ident} (#{file})" if file.present?
      ident
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include RenderMethods

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  # Each instance translates to a distinct line in the flash message.
  #
  class FlashPart < FlashHelper::FlashPart

    include UploadWorkflow::Errors::RenderMethods

    # =========================================================================
    # :section: FlashHelper::FlashPart overrides
    # =========================================================================

    protected

    # A hook for treating the first part of a entry as special.
    #
    # @param [Any]  src
    # @param [Hash] opt
    #
    # @return [String, ActiveSupport::SafeBuffer, nil]
    #
    def render_topic(src, **opt)                                                # NOTE: to Record::Exceptions::FlashPart
      src = make_label(src, default: '').presence || src
      super(src, **opt)
    end

  end

  # Exception raised when a submission is incomplete or invalid.
  #
  class SubmitError < ExecError
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Raise an exception.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [Any, nil]                                                  value
  #
  # @raise [UploadWorkflow::SubmitError]
  # @raise [ExecError]
  #
  # @see ExceptionHelper#failure
  #
  def failure(problem, value = nil)                                             # NOTE: to Record::Exceptions
    ExceptionHelper.failure(problem, value, model: :upload)
  end

end

# Workflow properties that can be set via URL parameters.
#
module UploadWorkflow::Properties                                               # NOTE: to Record::Properties (all)

  #include Workflow::Base::Properties
  include UploadWorkflow::Errors

  # ===========================================================================
  # :section: Constants
  # ===========================================================================

  public

  # The Federated Ingest API cannot accept more than 1000 items; this puts a
  # hard upper-bound on batch sizes and the size of input values that certain
  # methods can accept.
  #
  # @type [Integer]
  #
  INGEST_MAX_SIZE = 1000

  # A string added to the start of each title created on a non-production
  # instance to help distinguish it from other index results.
  #
  # @type [String]
  #
  DEV_TITLE_PREFIX = 'RWL'

  # A string added to the start of each title.
  #
  # This should normally be *nil*.
  #
  # @type [String, nil]
  #
  # @see #title_prefix
  #
  TITLE_PREFIX = (DEV_TITLE_PREFIX unless application_deployed?)

  # A fractional number of seconds to pause between iterations.
  #
  # If *false* or *nil* then throttling will not occur.
  #
  # @type [Float, FalseClass, nil]
  #
  THROTTLE_PAUSE = 0.01

  # ===========================================================================
  # :section: Property defaults
  # ===========================================================================

  public

  # Force deletions of Unified Index entries regardless of whether the item is
  # in the "uploads" table.
  #
  # When *false*, items that cannot be found in the "uploads" table are treated
  # as failures.
  #
  # When *true*, items identified by submission ID will be included in the
  # argument list to #remove_from_index unconditionally.
  #
  # @type [Boolean]
  #
  # @see #force_delete
  #
  FORCE_DELETE_DEFAULT = true

  # Force deletions of Unified Index entries even if the record ID does not
  # begin with "emma-".  (This is to support development during which sometimes
  # fake member repository entries get into the index.)
  #
  # When *false*, only items with :emma_repositoryRecordId values beginning
  # with "emma-" will be submitted to Federated Search Ingest.  All other will
  # result in generating a request for consideration by the member repository.
  #
  # When *true*, all items will be submitted to Federated Search Ingest.
  #
  # @type [Boolean]
  #
  # @see #emergency_delete
  #
  EMERGENCY_DELETE_DEFAULT = false

  # For the special case of deleting all records (effectively wiping the
  # database) this controls whether the next available ID should be set to 1.
  #
  # Otherwise, the next record after removing all records will have an 'id'
  # which is 1 greater than the last record prior to the deletion.
  #
  # When *false*, do not truncate the "uploads" table.
  #
  # When *true*, truncate the "uploads" table, resetting the initial ID to 1.
  #
  # @type [Boolean]
  #
  TRUNCATE_DELETE_DEFAULT = true

  # Permit the "creation" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @type [Boolean]
  #
  REPO_CREATE_DEFAULT = true

  # Permit the "update" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @type [Boolean]
  #
  REPO_EDIT_DEFAULT = false

  # Permit the "removal" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @type [Boolean]
  #
  REPO_REMOVE_DEFAULT = false

  # Default size for batching.
  #
  # If *false* or *nil* then no batching will occur.
  #
  # @type [Integer, FalseClass, nil]
  #
  # @see #BATCH_SIZE
  #
  BATCH_SIZE_DEFAULT = 10

  # Batches larger than this number are not permitted.
  #
  # @type [Integer]
  #
  MAX_BATCH_SIZE = INGEST_MAX_SIZE - 1

  # Break sets of submissions into chunks of this size.
  #
  # This is the value returned by #batch_size unless a different size was
  # explicitly given via the :batch URL parameter.
  #
  # @type [Integer]
  #
  # @see #set_bulk_batch
  # @see #MAX_BATCH_SIZE
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  BATCH_SIZE = [
    (ENV['BATCH_SIZE']&.to_i || BATCH_SIZE_DEFAULT || MAX_BATCH_SIZE),
    MAX_BATCH_SIZE
  ].min

  # URL parameter names and default values.
  #
  # @type [Hash{Symbol=>Any}]
  #
  OPTION_PARAMETER_DEFAULT = {
    prefix:       TITLE_PREFIX,
    batch:        BATCH_SIZE,
    force:        FORCE_DELETE_DEFAULT,
    emergency:    EMERGENCY_DELETE_DEFAULT,
    truncate:     TRUNCATE_DELETE_DEFAULT,
    repo_create:  REPO_CREATE_DEFAULT,
    repo_edit:    REPO_EDIT_DEFAULT,
    repo_remove:  REPO_REMOVE_DEFAULT,
  }.freeze

  # Module method mapped to URL parameter.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  OPTION_METHOD_MAP = {
    prefix:      :title_prefix,
    batch:       :batch_size,
    force:       :force_delete,
    emergency:   :emergency_delete,
    truncate:    :truncate_delete,
    repo_create: :repo_create,
    repo_edit:   :repo_edit,
    repo_remove: :repo_remove,
  }.freeze

  # URL parameter mapped to module method.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  OPTION_PARAMETER_MAP = OPTION_METHOD_MAP.invert.freeze

  # ===========================================================================
  # :section: Property values
  # ===========================================================================

  public

  # A string added to the start of each title.
  #
  # @return [String]                  Value to prepend to title.
  # @return [FalseClass]              No prefix should be used.
  # @return [nil]                     No prefix is defined.
  #
  # @see #TITLE_PREFIX
  #
  # == Usage Notes
  # The prefix cannot match any of #TRUE_VALUES or #FALSE_VALUES.
  #
  def title_prefix
    key   = OPTION_PARAMETER_MAP[__method__]
    value = parameters[key]
    return false if false?(value)
    value = nil  if true?(value)
    value&.to_s || OPTION_PARAMETER_DEFAULT[key]
  end

  # Force deletions of Unified Index entries regardless of whether the item is
  # in the "uploads" table.
  #
  # @return [Boolean]
  #
  # @see #FORCE_DELETE_DEFAULT
  #
  def force_delete
    key = OPTION_PARAMETER_MAP[__method__]
    parameter_setting(key)
  end

  # Force deletions of Unified Index entries even if the record ID does not
  # begin with "emma-".  (This is to support development during which sometimes
  # fake member repository entries get into the index.)
  #
  # @return [Boolean]
  #
  # @see #EMERGENCY_DELETE_DEFAULT
  #
  def emergency_delete
    key = OPTION_PARAMETER_MAP[__method__]
    parameter_setting(key)
  end

  # If all "uploads" records are removed, reset the next ID to 1.
  #
  # @return [Boolean]
  #
  # @see #TRUNCATE_DELETE_DEFAULT
  #
  def truncate_delete
    key = OPTION_PARAMETER_MAP[__method__]
    parameter_setting(key)
  end

  # Permit the "creation" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @return [Boolean]
  #
  # @see #REPO_CREATE_DEFAULT
  #
  def repo_create
    key = OPTION_PARAMETER_MAP[__method__]
    # TODO: conditionally accept repo_create based on user?
    OPTION_PARAMETER_DEFAULT[key]
  end

  # Permit the "update" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @return [Boolean]
  #
  # @see #REPO_EDIT_DEFAULT
  #
  def repo_edit
    key = OPTION_PARAMETER_MAP[__method__]
    # TODO: conditionally accept repo_edit based on user?
    OPTION_PARAMETER_DEFAULT[key]
  end

  # Permit the "removal" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @return [Boolean]
  #
  # @see #REPO_REMOVE_DEFAULT
  #
  def repo_remove
    key = OPTION_PARAMETER_MAP[__method__]
    # TODO: conditionally accept repo_remove based on user?
    OPTION_PARAMETER_DEFAULT[key]
  end

  # Handle bulk operations in batches.
  #
  # If this is disabled, the method returns *false*; otherwise it returns the
  # batch size.
  #
  # @return [Integer]                 Bulk batch size.
  # @return [FalseClass]              Bulk operations should not be batched.
  #
  # @see #set_bulk_batch
  #
  def batch_size
    key   = OPTION_PARAMETER_MAP[__method__]
    value = parameters[key]
    return false if false?(value)
    value = positive(value)
    # noinspection RubyMismatchedReturnType
    value ? [value, MAX_BATCH_SIZE].min : OPTION_PARAMETER_DEFAULT[key]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # This provides URL parameters in either the context of the controller (via
  # UploadConcern) or in the context of the workflow instance (through the
  # parameters saved from the :params initializer option).
  #
  # @return [Hash{Symbol=>Any}]
  #
  # @see Upload::Options#model_params
  # @see Workflow::Base::Properties#parameters
  #
  def parameters
    # noinspection RailsParamDefResolve
    try(:model_params) || super || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Extract the named URL parameter from *params*.
  #
  # @param [Symbol]    key            URL parameter name.
  # @param [Hash, nil] prm            Default: `#parameters`.
  #
  # @return [Boolean]
  #
  # == Implementation Notes
  # If *default* is *false* then *true* is returned only if *value* is "true".
  # If *default* is *true* then *false* is returned only if *value* is "false".
  #
  def parameter_setting(key, prm = nil)
    prm   ||= parameters
    value   = prm&.dig(key)
    default = OPTION_PARAMETER_DEFAULT[key]
    case value
      when true, false then value
      when nil         then default
      else                  default ? !false?(value) : true?(value)
    end
  end

end

# =============================================================================
# :section: Core
# =============================================================================

public

# Fundamental upload mechanisms for managing submissions which entail:
#
# * File storage/retrieval/removal
# * Database create/update/delete
# * Federated Index create/update/delete
# * Member repository submission queue (AWS S3) create/update/delete
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module UploadWorkflow::External

  include Workflow::Base::External
  include UploadWorkflow::Properties
  include UploadWorkflow::Events

  include ExecReport::Constants

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current AWS API service instance.
  #
  # @return [AwsS3Service]
  #
  def aws_api                                                                   # NOTE: to Record::Submittable::MemberRepositoryMethods
    AwsS3Service.instance
  end

  # Current Ingest API service instance.
  #
  # @return [IngestService]
  #
  def ingest_api                                                                # NOTE: to Record::Submittable::IndexIngestMethods
    IngestService.instance
  end

  # Indicate whether the item represents an EMMA repository entry (as opposed
  # to a member repository entry).
  #
  # @param [Upload, String, #emma_repository, #emma_recordId, Any] item
  #
  # @see Upload#valid_sid?
  # @see Upload#emma_native?
  #
  def emma_item?(item)                                                          # NOTE: to Record::Submittable::RecordMethods
    return true if item.is_a?(Upload) && item.repository.nil?
    digits_only?(item) || Upload.valid_sid?(item) || Upload.emma_native?(item)
  end

  # Indicate whether the item does not represent an existing EMMA entry.
  #
  # @param [Model, String, Any] item
  #
  def incomplete?(item)                                                         # NOTE: to Record::Submittable::RecordMethods
    item.is_a?(Upload) && !item.existing_entry?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Add a new submission to the database, upload its file to storage, and add
  # a new index entry for it (if explicitly requested).
  #
  # @param [Boolean] index            If *true*, update index.
  # @param [Boolean] atomic           Passed to #add_to_index.
  # @param [Hash]    data             @see Upload#assign_attributes.
  #
  # @return [Array<(Upload,Array)>]   Record instance; zero or more messages.
  # @return [Array<(nil,Array)>]      No record; one or more error messages.
  #
  # @see #db_insert
  # @see #add_to_index
  #
  # == Implementation Notes
  # Compare with UploadWorkflow::Bulk::External#bulk_upload_create
  #
  def upload_create(index: nil, atomic: true, **data)                           # NOTE: to Record::Submittable::SubmissionMethods#entry_create
    __debug_items("UPLOAD WF #{__method__}", binding)

    # Save the Upload record to the database.
    item = db_insert(data)
    return nil,  ['Entry not created'] unless item.is_a?(Upload) # TODO: I18n
    return item, item.errors           if item.errors.present?

    # Include the new submission in the index if specified.
    return item, [] unless index
    succeeded, failed, _ = add_to_index(item, atomic: atomic)
    return succeeded.first, failed
  end

  # Update an existing database record and update its associated index entry
  # (if explicitly requested).
  #
  # @param [Boolean] index            If *true*, update index.
  # @param [Boolean] atomic           Passed to #update_in_index.
  # @param [Hash]    data             @see Upload#assign_attributes
  #
  # @return [Array<(Upload,Array)>]   Record instance; zero or more messages.
  # @return [Array<(nil,Array)>]      No record; one or more error messages.
  #
  # @see #db_update
  # @see #update_in_index
  #
  # == Implementation Notes
  # Compare with UploadWorkflow::Bulk::External#bulk_upload_edit
  #
  def upload_edit(index: nil, atomic: true, **data)                             # NOTE: to Record::Submittable::SubmissionMethods#entry_edit
    __debug_items("UPLOAD WF #{__method__}", binding)
    if (id = data[:id]).blank?
      if (id = data[:submission_id]).blank?
        return nil, ['No identifier provided'] # TODO: I18n
      elsif !Upload.valid_sid?(id)
        return nil, ["Invalid EMMA submission ID #{id}"] # TODO: I18n
      end
    end

    # Fetch the Upload record and update it in the database.
    item = db_update(data)
    return nil, ["Entry #{id} not found"] unless item.is_a?(Upload) # TODO: I18n
    return item, item.errors              if item.errors.present?

    # Update the index with the modified submission if specified.
    return item, [] unless index
    succeeded, failed, _ = update_in_index(item, atomic: atomic)
    return succeeded.first, failed
  end

  # Remove Upload records from the database and from the index.
  #
  # @param [Array<Upload,String,Array>] items   @see #collect_records
  # @param [Boolean]                    index   *false* -> no index update
  # @param [Boolean]                    atomic  *true* == all-or-none
  # @param [Boolean]                    force   Force removal of index entries
  #                                               even if the related database
  #                                               entries do not exist.
  #
  # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
  #
  # @see #remove_from_index
  #
  # == Usage Notes
  # Atomicity of the record removal phase rests on the assumption that any
  # database problem(s) would manifest with the very first destruction attempt.
  # If a later item fails, the successfully-destroyed items will still be
  # removed from the index.
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def upload_remove(*items, index: nil, atomic: true, force: nil, **opt)        # NOTE: to Record::Submittable::SubmissionMethods
    __debug_items("UPLOAD WF #{__method__}", binding)

    # Translate items into Upload record instances.
    items, failed = collect_records(*items, force: force)
    requested = []
    if force
      emergency = opt[:emergency] || model_options.emergency_delete
      # Mark as failed any non-EMMA-items that could not be added to a request
      # for removal of member repository items.
      items, failed =
        items.partition do |item|
          emma_item?(item) || incomplete?(item) ||
            (Upload.sid_for(item) if emergency)
        end
      if model_options.repo_remove
        deferred = opt.key?(:requests)
        requests = opt.delete(:requests) || {}
        failed.delete_if do |item|
          next unless (repo = Upload.repository_of(item))
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
        if !item.is_a?(Upload)
          item                        # Only seen if *force* is *true*.
        elsif db_delete(item)
          throttle(counter)
          counter += 1
          destroyed << item
          item
        elsif atomic && destroyed.blank?
          return [], [item]           # Early return with the problem item.
        else
          retained << item and next   # Will not be included in *items*.
        end
      }.compact
    if retained.present?
      Log.warn do
        msg = [__method__]
        msg << 'not atomic' if atomic
        msg << 'items retained in the database that will be de-indexed'
        msg << retained.map { |item| make_label(item) }.join(', ')
        msg.join(': ')
      end
      retained.map! { |item| FlashPart.new(item, 'not removed') } # TODO: I18n
    end

    # Remove the associated entries from the index.
    return items, retained unless index && items.present?
    succeeded, failed = remove_from_index(*items, atomic: atomic)
    return (succeeded + requested), (retained + failed)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Bulk removal.
  #
  # @param [Array<String,Integer,Hash,Upload>] ids
  # @param [Boolean] index            If *false*, do not update index.
  # @param [Boolean] atomic           If *false*, do not stop on failure.
  # @param [Boolean] force            Default: `#force_delete`.
  # @param [Hash]    opt              Passed to #upload_remove via
  #                                     #batch_upload_operation.
  #
  # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
  #
  # @see UploadWorkflow::External#upload_remove
  #
  def batch_upload_remove(ids, index: true, atomic: true, force: nil, **opt)    # NOTE: to Record::Submittable::BatchMethods
    __debug_items("UPLOAD WF #{__method__}", binding)
    ids = Array.wrap(ids)

    # Translate items into record instances if possible.
    items, failed = collect_records(*ids, force: force)
    return [], failed if atomic && failed.present? || items.blank?

    # Batching occurs unconditionally in order to ensure that the requested
    # items can be successfully removed from the index.
    opt[:requests] ||= {} if model_options.repo_remove
    opt.merge!(index: index, atomic: atomic, force: force)
    succeeded, failed = batch_upload_operation(:upload_remove, items, **opt)

    # After all batch operations have completed, truncate the database table
    # (i.e., so that the next entry starts with id == 1) if appropriate.
    if model_options.truncate_delete && (ids == %w(*))
      if failed.present?
        Log.warn('database not truncated due to the presence of errors')
      elsif !Upload.connection.truncate(Upload.table_name)
        Log.warn("cannot truncate '#{Upload.table_name}'")
      end
    end

    # Member repository removal requests that were deferred in #upload_remove
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
  # @param [Symbol]                            op
  # @param [Array<String,Integer,Hash,Upload>] items
  # @param [Integer, Boolean]                  size     Default: #BATCH_SIZE.
  # @param [Hash]                              opt
  #
  # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
  #
  def batch_upload_operation(op, items, size: nil, **opt)                       # NOTE: to Record::Submittable::BatchMethods
    __debug_items((dbg = "UPLOAD WF #{op}"), binding)
    opt[:bulk] ||= { total: items.size }

    # Set batch size for this iteration.
    size = model_options.batch_size if size.nil?
    size = -1                       if size.is_a?(FalseClass)
    size =  0                       if size.is_a?(TrueClass)
    size = size.to_i
    size = items.size               if size.negative?
    size = BATCH_SIZE               if size.zero?
    size = MAX_BATCH_SIZE           if size > MAX_BATCH_SIZE

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

  # Release the current thread to the scheduler.
  #
  # @param [Integer]       counter    Iteration counter.
  # @param [Integer]       frequency  E.g., '3' indicates every third iteration
  # @param [Float,Boolean] pause      Default: `#THROTTLE_PAUSE`.
  #
  # @return [void]
  #
  def throttle(counter, frequency: 1, pause: true)                              # NOTE: to Record::Submittable::BatchMethods
    pause = THROTTLE_PAUSE if pause.is_a?(TrueClass)
    return if pause.blank?
    return if counter.zero?
    return if (counter % frequency).nonzero?
    sleep(pause)
  end

  # ===========================================================================
  # :section: Records
  # ===========================================================================

  public

  # The database ID for the item, or, failing that, the submission ID.
  #
  # @param [Upload, Hash, String] item
  #
  # @return [String]                  Record :id or :submission_id.
  # @return [nil]                     No identifier could be determined.
  #
  def identifier(item)
    Upload.id_for(item) || Upload.sid_for(item)
  end

  # Return an array of the characteristic identifiers for the item.
  #
  # @param [Upload, Hash, String] item
  #
  # @return [Array<String>]
  #
  def identifiers(item)
    [Upload.id_for(item), Upload.sid_for(item)].compact
  end

  # Return with the specified record or *nil* if one could not be found.
  #
  # @param [String, Hash, Upload, nil] id
  # @param [Boolean]        no_raise  If *true*, do not raise exceptions.
  # @param [Symbol]         meth      Calling method (for logging).
  #
  # @raise [UploadWorkflow::SubmitError]  If *item* not found and !*no_raise*.
  #
  # @return [Upload]                  The item; from the database if necessary.
  # @return [nil]                     If *item* not found and *no_raise*.
  #
  def get_record(id, no_raise: false, meth: nil)                                # NOTE: to Record::Identification#find_record
    if (result = Upload.get_record(id))
      result
    elsif Upload.id_term(id).values.first.blank?
      failure(:file_id) unless no_raise
    elsif no_raise
      Log.warn  { "#{meth || __method__}: #{id}: skipping record" }
    else
      Log.error { "#{meth || __method__}: #{id}: non-existent record" }
      failure(:find, id)
    end
  end

  # Find all of the specified Upload records.
  #
  # @param [Array<Upload,String,Array>] items
  # @param [Hash]                       opt     Passed to #collect_records.
  #
  # @return [Array<Upload>]
  #
  def find_records(*items, **opt)                                               # NOTE: to Record::Identification
    collect_records(*items, **opt).first || []
  end

  # Create a new free-standing (un-persisted) Upload instance.
  #
  # @param [Hash, Upload, nil] data        Passed to Upload#initialize.
  #
  # @return [Upload]
  #
  # @see #add_title_prefix
  #
  def new_record(data = nil)                                                    # NOTE: to Record::Submittable::RecordMethods
    __debug_items("UPLOAD WF #{__method__}", binding)
    Upload.new(data).tap do |record|
      # noinspection RubyMismatchedArgumentType
      p = model_options.title_prefix and add_title_prefix(record, prefix: p)
    end
  end

  # ===========================================================================
  # :section: Records
  # ===========================================================================

  protected

  # Transform a mixture of Upload objects and record identifiers into a list of
  # Upload objects.
  #
  # @param [Array<Upload,String,Array>] items   @see Upload#expand_ids
  # @param [Boolean]                    all     If *true*, empty *items* is OK.
  # @param [Boolean]                    force   See Usage Notes
  # @param [Hash]                       opt     Passed to Upload#get_records.
  #
  # @raise [StandardException] If *all* is *true* and *items* were supplied.
  #
  # @return [Array<(Array<Upload>,Array)>]      Upload records and failed ids.
  # @return [Array<(Array<Upload,String>,[])>]  If *force* is *true*.
  #
  # == Usage Notes
  # If *force* is true, the returned list of failed records will be empty but
  # the returned list of items may contain a mixture of Upload and String
  # elements.
  #
  def collect_records(*items, all: false, force: false, **opt)                  # NOTE: to Record::Identification
    raise 'If :all is true then no items are allowed'  if all && items.present?
    opt = items.pop if items.last.is_a?(Hash) && opt.blank?
    Log.warn { "#{__method__}: no criteria supplied" } if all && opt.blank?
    items  = items.flatten.compact
    failed = []
    if items.present?
      # Searching by identifier (possibly modified by other criteria).
      items =
        items.flat_map { |item|
          item.is_a?(Upload) ? item : Upload.expand_ids(item) if item.present?
        }.compact
      identifiers = items.reject { |item| item.is_a?(Upload) }
      if identifiers.present?
        found = {}
        Upload.get_records(*identifiers, **opt).each do |record|
          (id  = record.id.to_s).present?       and (found[id]  = record)
          (sid = record.submission_id).present? and (found[sid] = record)
        end
        items.map! { |item| !item.is_a?(Upload) && found[item] || item }
        items, failed = items.partition { |i| i.is_a?(Upload) } unless force
      end
    elsif all
      # Searching for non-identifier criteria (e.g. { user: @user }).
      items = Upload.get_records(**opt)
    end
    return items, failed
  end

  # If a prefix was specified, apply it to the record's title.
  #
  # @param [Upload] record
  # @param [String] prefix
  #
  # @return [void]
  #
  def add_title_prefix(record, prefix:)                                         # NOTE: to Record::Submittable::RecordMethods
    return unless prefix.present?
    return unless record.respond_to?(:active_emma_metadata)
    return unless (title = record.active_emma_metadata[:dc_title])
    prefix = "#{prefix} - " unless prefix.match?(/[[:punct:]]\s*$/)
    prefix = "#{prefix} "   unless prefix.end_with?(' ')
    return if title.start_with?(prefix)
    record.modify_active_emma_data(dc_title: "#{prefix}#{title}")
  end

  # ===========================================================================
  # :section: Storage
  # ===========================================================================

  protected

  # Upload file via Shrine.                                                     # NOTE: to Record::Uploadable#upload_file
  #
  # @param [Hash] opt
  #
  # @option opt [Rack::Request::Env] :env
  #
  # @return [Array<(Integer, Hash{String=>Any}, Array<String>)>]
  #
  # @see Shrine::Plugins::UploadEndpoint::ClassMethods#upload_response
  #
  def upload_file(**opt)
    fault!(opt) # @see UploadWorkflow::Testing
    FileUploader.upload_response(:cache, opt[:env])
  end

  # ===========================================================================
  # :section: Database
  # ===========================================================================

  public

  # Add a single Upload record to the database.
  #
  # @param [Upload, Hash] data        @see Upload#assign_attributes.
  #
  # @return [Upload]
  #
  def db_insert(data)                                                           # NOTE: to Record::Submittable::DatabaseMethods
    __debug_items("UPLOAD WF #{__method__}", binding)
    fault!(data) # @see UploadWorkflow::Testing
    record = data.is_a?(Upload) ? data : new_record(data)
    record.save if record.new_record?
    record
  end

  # Modify a single existing Upload database record.
  #
  # @param [Upload, Hash, String] record
  # @param [Hash, nil]            data
  #
  # @return [Upload]                  The provided or located record.
  # @return [nil]                     If the record was not found or updated.
  #
  def db_update(record, data = nil)                                             # NOTE: to Record::Submittable::DatabaseMethods
    __debug_items("UPLOAD WF #{__method__}", binding)
    record, data = [nil, record] if record.is_a?(Hash)
    unless record.is_a?(Upload)
      if data.is_a?(Hash)
        data = data.dup
        opt  = extract_hash!(data, :no_raise, :meth)
        ids  = extract_hash!(data, :id, :submission_id)
        id   = record || ids.values.first
      else
        opt  = {}
        data = nil
        id   = record
      end
      record = get_record(id, **opt)
    end
    return unless record
    if data.present?
      record.update(data)
    elsif record.new_record?
      record.save
    end
    # noinspection RubyMismatchedReturnType
    record
  end

  # Remove a single existing Upload record from the database.
  #
  # @param [Upload, Hash, String] data
  #
  # @return [Any]
  # @return [nil]                     If the record was not found or removed.
  #
  def db_delete(data)                                                           # NOTE: to Record::Submittable::DatabaseMethods
    __debug_items("UPLOAD WF #{__method__}", binding)
    record = data.is_a?(Upload) ? data : get_record(data)
    record&.destroy
  end

  # ===========================================================================
  # :section: Index ingest
  # ===========================================================================

  public

  # As a convenience for testing, sending to the Federated Search Ingest API    # NOTE: to Record::Submittable::IndexIngestMethods
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
  # @param [Array<Upload>] items
  # @param [Boolean]       atomic
  #
  # @raise [Api::Error] @see IngestService::Request::Submissions#put_records
  #
  # @return [Array<(Array,Array,Array)>]  Succeeded records, failed item
  #                                         msgs, and records to roll back.
  #
  def add_to_index(*items, atomic: true, **)                                    # NOTE: to Record::Submittable::IndexIngestMethods
    __debug_items("UPLOAD WF #{__method__}", binding)
    succeeded, failed, rollback = update_in_index(*items, atomic: atomic)
    if rollback.present?
      # Any submissions that could not be added to the index will be removed
      # from the database.  The assumption here is that they failed because
      # they were missing information and need to be re-submitted anyway.
      removed, kept = upload_remove(*rollback, atomic: false)
      if removed.present?
        sids = removed.map(&:submission_id)
        Log.info { "#{__method__}: removed: #{sids}" }
        rollback.reject! { |item| sids.include?(item.submission_id) }
      end
      succeeded = [] if atomic
      failed += kept if kept.present?
      rollback.each(&:delete_file)
    end
    return succeeded, failed, rollback
  end

  # Add/modify the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload>] items
  # @param [Boolean]       atomic
  #
  # @raise [Api::Error] @see IngestService::Request::Submissions#put_records
  #
  # @return [Array<(Array,Array,Array)>]  Succeeded records, failed item
  #                                         msgs, and records to roll back.
  #
  def update_in_index(*items, atomic: true, **)                                 # NOTE: to Record::Submittable::IndexIngestMethods
    __debug_items("UPLOAD WF #{__method__}", binding)
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
  # @param [Array<Upload, String>] items
  # @param [Boolean]               atomic
  #
  # @raise [Api::Error] @see IngestService::Request::Submissions#delete_records
  #
  # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
  #
  def remove_from_index(*items, atomic: true, **)                               # NOTE: to Record::Submittable::IndexIngestMethods
    __debug_items("UPLOAD WF #{__method__}", binding)
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

    def skip_index_ingest(meth, *items)                                         # NOTE: to Record::Submittable::IndexIngestMethods
      __debug { "** SKIPPING ** UPLOAD #{meth} | items = #{items.inspect}" }
      return items, []
    end

  end

  # ===========================================================================
  # :section: Index ingest
  # ===========================================================================

  protected

  # Interpret error message(s) generated by Federated Ingest to determine which # NOTE: to Record::Submittable::IndexIngestMethods
  # item(s) failed.
  #
  # @param [Ingest::Message::Response, Hash{String,Integer=>String}] result
  # @param [Array<Upload, String>]                                   items
  # @param [Hash]                                                    opt
  #
  # @return [Array<(Array,Array,Array)>]  Succeeded records, failed item
  #                                         msgs, and records to roll back.
  #
  # @see ExecReport#error_table
  #
  # == Implementation Notes
  # It's not clear whether there would ever be situations where there was a mix
  # of errors by index, errors by submission ID, and/or general errors, but
  # this method was written to be able to cope with the possibility.
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
      by_index.transform_keys! { |idx| Upload.sid_for(items[idx-1]) }
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
      sids = sids.map { |v| Upload.sid_for(v) }.uniq
      rollback, succeeded =
        items.partition { |itm| sids.include?(itm.submission_id) }
    end

    return succeeded, failed, rollback
  end

  # Return a flatten array of items.
  #
  # @param [Array<Upload, String, Array>] items
  # @param [Symbol, nil]                  meth    The calling method.
  # @param [Integer]                      max     Maximum number to ingest.
  #
  # @raise [SubmitError] If the number of items is too large to be ingested.
  #
  # @return [Array]
  #
  def normalize_index_items(*items, meth: nil, max: INGEST_MAX_SIZE)            # NOTE: to Record::Submittable::IndexIngestMethods
    items = items.flatten.compact
    # noinspection RubyMismatchedReturnType
    return items unless items.size > max
    error = "#{meth || __method__}: item count: #{item.size} > #{max}"
    Log.error(error)
    failure(error)
  end

  # ===========================================================================
  # :section: Member repository requests
  # ===========================================================================

  public

  # Failure messages for member repository requests. # TODO: I18n               # NOTE: to Record::Submittable::MemberRepositoryMethods
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
  # @param [Array<Upload>] items
  # @param [Hash]          opt
  #
  # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
  #
  def repository_create(*items, **opt)                                          # NOTE: to Record::Submittable::MemberRepositoryMethods
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
  # @param [Array<Upload>] items
  # @param [Hash]          opt
  #
  # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
  #
  # @note This capability is not yet supported by any member repository.
  #
  def repository_modify(*items, **opt)                                          # NOTE: to Record::Submittable::MemberRepositoryMethods
    succeeded = []
    failed    = []
    if items.blank?
      failed << REPO_FAILURE[:no_items]
    elsif !repo_edit
      failed << REPO_FAILURE[:no_edit]
    else
      result = aws_api.modification_request(*items, **opt)
      succeeded, failed = process_aws_errors(result, *items)
    end
    return succeeded, failed
  end

  # Request deletion of a prior submission to a member repository.
  #
  # @param [Array<String,Upload>] items
  # @param [Hash]                 opt
  #
  # @return [Array<(Array,Array)>]  Succeeded items and failed item messages.
  #
  # @note This capability is not yet supported by any member repository.
  #
  def repository_remove(*items, **opt)                                          # NOTE: to Record::Submittable::MemberRepositoryMethods
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

  # ===========================================================================
  # :section: Member repository requests
  # ===========================================================================

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
  def repository_dequeue(*items, **opt)                                         # NOTE: to Record::Submittable::MemberRepositoryMethods
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

  # ===========================================================================
  # :section: Member repository requests
  # ===========================================================================

  protected

  # Interpret error message(s) generated by AWS S3.                            # NOTE: to Record::Submittable::MemberRepositoryMethods
  #
  # @param [AwsS3::Message::Response, Hash{String,Integer=>String}] result
  # @param [Array<String, Upload>]                                  items
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

  # ===========================================================================
  # :section: Member repository requests
  # ===========================================================================

  public

  # Send removal request(s) to member repositories.
  #
  # @param [Hash, Array] items
  # @param [Hash]        opt          Passed to #repository_remove.
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
  def repository_removals(items, **opt)                                         # NOTE: to Record::Submittable::MemberRepositoryMethods
    succeeded = []
    failed    = []
    repository_requests(items).each_pair do |_repo, repo_items|
      repo_items.map! { |item| Upload.record_id(item) }
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
  def repository_dequeues(items, **opt)                                         # NOTE: to Record::Submittable::MemberRepositoryMethods
    succeeded = []
    failed    = []
    repository_requests(items).each_pair do |_repo, repo_items|
      repo_items.map! { |item| Upload.record_id(item) }
      s, f = repository_dequeue(*repo_items, **opt)
      succeeded += s
      failed    += f
    end
    return succeeded, failed
  end

  # Transform items into arrays of requests per repository.
  #
  # @param [Hash, Array, Upload] items
  # @param [Boolean]             empty_key  If *true*, allow invalid items.
  #
  # @return [Hash{String=>Array<Upload>}]   One or more requests per repo.
  #
  #--
  # == Variations
  #++
  #
  # @overload repository_requests(hash, empty_key: false)
  #   @param [Hash{String=>Upload,Array<Upload>}] hash
  #   @param [Boolean]                            empty_key
  #   @return [Hash{String=>Array<Upload>}]
  #
  # @overload repository_requests(requests, empty_key: false)
  #   @param [Array<String,Upload,Any>]           requests
  #   @param [Boolean]                            empty_key
  #   @return [Hash{String=>Array<Upload>}]
  #
  # @overload repository_requests(request, empty_key: false)
  #   @param [Upload]                             request
  #   @param [Boolean]                            empty_key
  #   @return [Hash{String=>Array<Upload>}]
  #
  def repository_requests(items, empty_key: false)                              # NOTE: to Record::Submittable::MemberRepositoryMethods
    return {} if items.blank?
    case items
      when Array, Upload
        items  = (items.is_a?(Array) ? items.flatten : [items]).compact_blank
        result = items.group_by { |request| Upload.repository_of(request) }
      when Hash
        result = items.transform_values { |requests| Array.wrap(requests) }
      else
        result = {}
        Log.error { "#{__method__}: expected 'items' type: #{items.class}" }
    end
    empty_key ? result : result.delete_if { |repo, _| repo.blank? }
  end

end

# Workflow execution status information.
#
module UploadWorkflow::Data
  include Workflow::Base::Data
  include UploadWorkflow::External
end

# Methods used in the context of responding to workflow events.
#
module UploadWorkflow::Actions

  include Workflow::Base::Actions
  include UploadWorkflow::Data

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # wf_start_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_start_submission(*event_args)
    __debug_items(binding)
  end

  # wf_validate_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_validate_submission(*event_args)
    __debug_items(binding)
  end

  # wf_finalize_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_finalize_submission(*event_args)
    __debug_items(binding)
  end

  # wf_index_update
  #
  # @param [Array] _event_args        Ignored.
  #
  # @return [void]
  #
  def wf_index_update(*_event_args)
    __debug_items(binding)
  end

  # wf_list_items
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see Upload#expand_ids
  #
  def wf_list_items(*event_args)
    __debug_items(binding)
    event_args.pop if event_args.last.is_a?(Hash)
    force = model_options.force_delete
    items = Upload.expand_ids(*event_args.flatten.compact)
    emma_items, repo_items = items.partition { |item| emma_item?(item) }

    # EMMA items and/or EMMA submission ID's.
    opt = { no_raise: force }
    self.succeeded += emma_items.map { |item| get_record(item, **opt) || item }

    if repo_items.present?
      if force && model_options.repo_remove
        self.succeeded += repo_items.map { |item| Upload.record_id(item) }
      else
        self.failures  += repo_items
      end
    end
  end

  # wf_remove_items
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::External#batch_upload_remove
  #
  def wf_remove_items(*event_args)
    __debug_items(binding)
    opt = event_args.extract_options!
    opt.reverse_merge!(model_options.all)
    s, f = batch_upload_remove(event_args, **opt)
    self.succeeded = s
    self.failures += f
  end

  # wf_cancel_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_cancel_submission(*event_args)
    __debug_items(binding)
  end

end

# Stubs for methods supporting internal workflow simulated activity.
#
module UploadWorkflow::Simulation
  include Workflow::Base::Simulation
end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

# Methods which are executed to initiate state transitions.
#
module UploadWorkflow::Events
  include Workflow::Base::Events
  include UploadWorkflow::Simulation
end

# Methods executed on transition into and out of a state.
#
module UploadWorkflow::States
  include Workflow::Base::States
  include UploadWorkflow::Events
  include UploadWorkflow::Actions
end

# =============================================================================
# :section: Base for individual-entry workflows
# =============================================================================

public

if UploadWorkflow::SIMULATION
  require_relative '../../lib/sim/models/upload_workflow'
end

# Standard create/update/delete workflows.
#
# NOTE: Since the workflow gem is geared toward pre-Ruby-3 handling of options,
#   none of the methods for this and related classes/modules assume options are
#   passed as the final element of *args (rather than via keyword arguments).
#
class UploadWorkflow < Workflow::Base

  include UploadWorkflow::Events
  include UploadWorkflow::States
  include UploadWorkflow::Transitions
  include UploadWorkflow::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the workflow is dealing with the creation of a new EMMA
  # entry.
  #
  def new_submission?
    workflow_column.nil? || (workflow_column == Upload::PRIMARY_STATE_COLUMN)
  end

  # Indicate whether the workflow is dealing with the update/deletion of an
  # existing EMMA entry.
  #
  def existing_entry?
    !new_submission?
  end

  # ===========================================================================
  # :section:  Workflow overrides
  # ===========================================================================

  public

  # The 'uploads' table field associated with workflow state.
  #
  # @return [Symbol]
  #
  def self.workflow_column(...)
    Upload::PRIMARY_STATE_COLUMN
  end

  # ===========================================================================
  # :section: Workflow::Base overrides
  # ===========================================================================

  public

  # Return the workflow type which is a key under 'en.emma.workflow'.
  #
  # @return [Symbol]
  #
  def self.workflow_type
    name.underscore.remove(/_+workflow|workflow_*/i).tr('/', '_').to_sym
  end

  # ===========================================================================
  # :section:  Class methods
  # ===========================================================================

  protected

  # Sets up a direct descendent of this class to be the base of a set of
  # subclass variants.
  #
  # @param [UploadWorkflow] workflow_base
  #
  # @return [void]
  #
  def self.inherited(workflow_base)

    workflow_base.class_exec do

      # =======================================================================
      # :section: Workflow::Base overrides
      # =======================================================================

      public

      # Workflow model configuration.
      #
      # @return [Hash{Symbol=>Hash}]
      #
      def self.configuration
        # noinspection RbsMissingTypeSignature
        @configuration ||= super
      end

      # Workflow state labels.
      #
      # @return [Hash{Symbol=>Hash}]
      #
      def self.state_label
        # noinspection RbsMissingTypeSignature
        @state_label ||= super
      end

      # =======================================================================
      # :section: Workflow::Base overrides
      # =======================================================================

      public

      # Return the workflow type for the workflow base and its variants.
      #
      # @return [Symbol]
      #
      def self.workflow_type
        # noinspection RbsMissingTypeSignature
        @workflow_type ||= super
      end

      # Table of variant workflow types under this workflow base class.
      #
      # @return [Hash{Symbol=>Class<UploadWorkflow>}]
      #
      def self.variant_table
        # noinspection RbsMissingTypeSignature
        @variant_table ||=
          subclasses.map { |cls| [cls.variant_type, cls] }.sort.to_h
      end

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      protected

      # Called when the variant subclass is defined so that it is added to the
      # table of variants under this workflow base class.
      #
      # @param [Workflow::Base] workflow_variant
      #
      # @return [void]
      #
      def self.inherited(workflow_variant)

        workflow_variant.class_exec do

          # These methods are only meaningful in the context of the variant's
          # base class.
          class << self
            %i[
              configuration
              state_label
              workflow_type
              variant_table
              generate
            ].tap { |methods| delegate *methods, to: :superclass }
          end

          # The 'uploads' table field associated with workflow state.
          #
          # @return [Symbol]
          #
          # @see Workflow::ClassMethods#workflow_column
          #
          def self.workflow_column(...)
            # noinspection RbsMissingTypeSignature
            @workflow_state_column_name ||=
              safe_const_get(:STATE_COLUMN) || super
          end

          # Return the variant subclass type.
          #
          # @return [Symbol]
          #
          # @see Workflow::Base#variant_type
          #
          def self.variant_type
            # noinspection RbsMissingTypeSignature
            @variant_type ||= name.demodulize.to_s.underscore.to_sym
          end

        end

      end

    end

  end

end

__loading_end(__FILE__)
