# app/models/upload_workflow.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'workflow'

class UploadWorkflow < Workflow::Base
  # Initial declaration to establish the namespace.
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
  # :section:
  # ===========================================================================

  public

  # Placeholder error message.
  #
  # @type [String]
  #
  DEFAULT_ERROR_MESSAGE = I18n.t('emma.error.default', default: 'ERROR').freeze

  # Error types and messages.
  #
  # @type [Hash{Symbol=>(String,Class)}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  UPLOAD_ERROR =
    I18n.t('emma.error.upload').transform_values { |properties|
      text = properties[:message]
      err  = properties[:error]
      err  = "Net::#{err}" if err.is_a?(String) && !err.start_with?('Net::')
      err  = err&.safe_constantize unless err.is_a?(Module)
      err  = err.exception_type if err.respond_to?(:exception_type)
      [text, err]
    }.symbolize_keys.deep_freeze

  # ===========================================================================
  # :section: Modules
  # ===========================================================================

  public

  module RenderMethods

    # @private
    def self.included(base)
      base.send(:extend, self)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Default label. TODO: I18n
    #
    # @type [String]
    #
    DEFAULT_LABEL = '(missing)'

    # Show the submission ID if it can be determined for the given item(s).
    #
    # @param [Api::Record, Upload, Hash, String] item
    # @param [String]                            default
    #
    # @return [String]
    #
    def make_label(item, default: DEFAULT_LABEL)
      file  = (item.filename if item.is_a?(Upload))
      ident = Upload.sid_for(item) || Upload.id_for(item) || default
      ident = "Item #{ident}"      if digits_only?(ident) # TODO: I18n
      ident = "#{ident} (#{file})" if file.present?
      ident
    end

  end

  include RenderMethods

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  # Each instance translates to a distinct line in the flash message.
  #
  class ErrorEntry < FlashHelper::Entry

    include UploadWorkflow::Errors::RenderMethods

    # =========================================================================
    # :section: FlashHelper::Entry overrides
    # =========================================================================

    protected

    # Process a single object to make it a part.
    #
    # @param [*] part
    #
    # @return [String]
    #
    def transform(part)
      make_label(part, default: '').presence || super(part)
    end

  end

  # Exception raised when a submission is incomplete or invalid.
  #
  class SubmitError < StandardError

    # Individual error messages (if the originator supplied multiple messages).
    #
    # @return [Array<String>]
    #
    attr_reader :messages

    # Initialize a new instance.
    #
    # @param [Array<String>, String, nil] msg
    #
    def initialize(msg = nil)
      msg ||= UploadWorkflow::Errors::DEFAULT_ERROR_MESSAGE
      @messages = Array.wrap(msg)
      super(@messages.first)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Raise an exception.
  #
  # If *problem* is a symbol, it is used as a key to #UPLOAD_ERROR with *value*
  # used for string interpolation.
  #
  # Otherwise, error message(s) are extracted from *problem*.
  #
  # @param [Symbol,String,Array<String>,Exception,ActiveModel::Errors] problem
  # @param [*]                                                         value
  #
  # @raise [SubmitError]
  # @raise [Api::Error]
  # @raise [Net::ProtocolError]
  # @raise [RuntimeError]
  #
  def failure(problem, value = nil)
    __debug_items("UPLOAD WF #{__method__}", binding)

    # If any failure is actually an internal error, re-raise it now so that it
    # will result in a stack trace when it is caught and processed.
    raise problem if internal_exception?(problem)
    value = Array.wrap(value).each { |v| raise v if internal_exception?(v) }
    value = value.first if value.size <= 1

    err = nil
    case problem
      when Symbol              then msg, err = UPLOAD_ERROR[problem]
      when ActiveModel::Errors then msg = problem.full_messages
      when Api::Error          then msg = problem.messages
      when Exception           then msg = problem.message
      else                          msg = problem
    end
    err ||= SubmitError

    msg ||= DEFAULT_ERROR_MESSAGE
    msg   = msg.join('; ') if msg.is_a?(Array)
    intp  = msg.is_a?(String) && msg.include?('%') # Should interpolate value?
    case value
      when String
        msg = ERB::Util.h(msg) if (html = value.html_safe?)
        msg = intp ? (msg % value) : "#{msg}: #{value}"
        msg = html ? msg.html_safe : ERB::Util.h(msg)
      when Array
        # noinspection RubyNilAnalysis
        cnt = "(#{value.size})"
        msg = intp ? (msg % cnt) : "#{msg}: #{cnt}"
        msg = ["#{msg}:", *value.map { |v| ErrorEntry[v] }]
      else
        msg = ["#{msg}:", ErrorEntry[value]]
    end

    raise err, msg
  end

end

# Workflow properties that can be set via URL parameters.
#
#--
# noinspection RubyClassVariableUsageInspection
#++
module UploadWorkflow::Properties

  include Workflow::Base::Properties
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
  BATCH_SIZE = [
    (ENV['BATCH_SIZE']&.to_i || BATCH_SIZE_DEFAULT || MAX_BATCH_SIZE),
    MAX_BATCH_SIZE
  ].min

  # URL parameter names and default values.
  #
  # @type [Hash{Symbol=>*}]
  #
  WF_URL_PARAMETER = {
    prefix:       TITLE_PREFIX,
    force:        FORCE_DELETE_DEFAULT,
    emergency:    EMERGENCY_DELETE_DEFAULT,
    truncate:     TRUNCATE_DELETE_DEFAULT,
    repo_create:  REPO_CREATE_DEFAULT,
    repo_edit:    REPO_EDIT_DEFAULT,
    repo_remove:  REPO_REMOVE_DEFAULT,
    batch:        BATCH_SIZE
  }.freeze

  # ===========================================================================
  # :section: Property values
  # ===========================================================================

  public

  # A string added to the start of each title.
  #
  # @return [String]                  Value to prepend to title.
  # @return [FalseClass]              No prefix should be used.
  #
  # @see #TITLE_PREFIX
  #
  # == Usage Notes
  # The prefix cannot match any of #TRUE_VALUES or #FALSE_VALUES.
  #
  def title_prefix
    value = parameters[:prefix]
    if value.nil? || true?(value)
      TITLE_PREFIX
    elsif false?(value)
      false
    else
      value.to_s
    end
  end

  # Force deletions of Unified Index entries regardless of whether the item is
  # in the "uploads" table.
  #
  # @return [Boolean]
  #
  # @see #FORCE_DELETE_DEFAULT
  #
  def force_delete
    parameter_setting(:force)
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
    parameter_setting(:emergency)
  end

  # If all "uploads" records are removed, reset the next ID to 1.
  #
  # @return [Boolean]
  #
  # @see #TRUNCATE_DELETE_DEFAULT
  #
  def truncate_delete
    parameter_setting(:truncate)
  end

  # Permit the "creation" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @return [Boolean]
  #
  # @see #REPO_CREATE_DEFAULT
  #
  def repo_create
    #parameter_setting(:repo_create, params)
    REPO_CREATE_DEFAULT # TODO: conditionally accept based on user
  end

  # Permit the "update" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @return [Boolean]
  #
  # @see #REPO_EDIT_DEFAULT
  #
  def repo_edit
    #parameter_setting(:repo_edit, params)
    REPO_EDIT_DEFAULT # TODO: conditionally accept based on user
  end

  # Permit the "removal" of member repository items via a request to be queued
  # to the appropriate member repository.
  #
  # @return [Boolean]
  #
  # @see #REPO_REMOVE_DEFAULT
  #
  def repo_remove
    #parameter_setting(:repo_remove, params)
    REPO_REMOVE_DEFAULT # TODO: conditionally accept based on user
  end

  # Handle bulk uploads in batches.
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
    value = parameters[:batch]
    # noinspection RubyYardReturnMatch
    if value.blank?
      BATCH_SIZE
    elsif false?(value)
      false
    elsif true?(value)
      (value.to_s == '1') ? 1 : BATCH_SIZE
    elsif value.to_i.positive?
      [value.to_i, MAX_BATCH_SIZE].min
    else
      BATCH_SIZE
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # This provides URL parameters in either the context of the controller (via
  # UploadConcern) or in the context of the workflow instance (through the
  # parameters saved from the :params initializer option).
  #
  # @return [Hash, nil]
  #
  def parameters
    # noinspection RailsParamDefResolve
    try(:upload_params) || super || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Extract the named URL parameter from *params*.
  #
  # @param [Symbol]    key            URL parameter name.
  # @param [Hash, nil] params         Default: `#parameters`.
  #
  # @return [Boolean]
  #
  # == Implementation Notes
  # If *default* is *false* then *true* is returned only if *value* is "true".
  # If *default* is *true* then *false* is returned only if *value* is "false".
  #
  def parameter_setting(key, params = nil)
    params ||= parameters
    value    = params&.dig(key)
    default  = WF_URL_PARAMETER[key]
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
module UploadWorkflow::External

  include UploadWorkflow::Properties
  include UploadWorkflow::Events

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current AWS API service instance.
  #
  # @return [AwsS3Service]
  #
  def aws_api
    # noinspection RubyYardReturnMatch
    AwsS3Service.instance
  end

  # Current Ingest API service instance.
  #
  # @return [IngestService]
  #
  def ingest_api
    # noinspection RubyYardReturnMatch
    IngestService.instance
  end

  # Indicate whether the item represents an EMMA repository entry (as opposed
  # to a member repository entry).
  #
  # @param [Upload, String, #emma_repository, #emma_recordId, *] item
  #
  # @see Upload#valid_sid?
  # @see Upload#emma_native?
  #
  def emma_item?(item)
    return true if item.is_a?(Upload) && item.repository.nil?
    # noinspection RubyYardParamTypeMatch
    digits_only?(item) || Upload.valid_sid?(item) || Upload.emma_native?(item)
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
  # @return [(Upload,Array>]          Record and error messages.
  # @return [(nil,Array)]             No record; error message.
  #
  # @see #db_insert
  # @see #add_to_index
  #
  # Compare with:
  # @see UploadWorkflow::Bulk::External#bulk_upload_create
  #
  def upload_create(index: nil, atomic: true, **data)
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
  # @return [(Upload,Array>]          Record and error messages.
  # @return [(nil,Array)]             No record; error message.
  #
  # @see #db_update
  # @see #update_in_index
  #
  # Compare with:
  # @see UploadWorkflow::Bulk::External#bulk_upload_edit
  #
  def upload_edit(index: nil, atomic: true, **data)
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
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  # @see #remove_from_index
  #
  # == Usage Notes
  # Atomicity of the record removal phase rests on the assumption that any
  # database problem(s) would manifest with the very first destruction attempt.
  # If a later item fails, the successfully-destroyed items will still be
  # removed from the index.
  #
  def upload_remove(*items, index: nil, atomic: true, force: nil, **opt)
    __debug_items("UPLOAD WF #{__method__}", binding)

    # Translate entries into Upload record instances.
    items, failed = collect_records(*items, force: force)
    requested = []
    if force
      emergency = opt[:emergency] || emergency_delete
      # Mark as failed any non-EMMA-items that could not be added to a request
      # for removal of member repository items.
      items, failed =
        items.partition do |item|
          emma_item?(item) || (Upload.sid_for(item) if emergency)
        end
      if repo_remove
        deferred = opt.key?(:requests)
        requests = opt.delete(:requests) || {}
        failed.delete_if do |item|
          next unless (repo = Upload.repository_of(item))
          requests[repo] ||= []
          requests[repo] << item
          requested << item
        end
        batch_repository_remove(requests, **opt) unless deferred
      end
    end
    if atomic && failed.present? || items.blank?
      return (items + requested), failed
    end

    # Remove the records from the database.
    destroyed = []
    retained  = []
    counter   = 0
    items =
      items.map { |item|
        # noinspection RubyYardParamTypeMatch
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
      retained.map! { |item| ErrorEntry.new(item, 'not removed') } # TODO: I18n
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
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  # @see UploadWorkflow::External#upload_remove
  #
  def batch_upload_remove(ids, index: true, atomic: true, force: nil, **opt)
    __debug_items("UPLOAD WF #{__method__}", binding)
    ids = Array.wrap(ids)

    # Translate entries into Upload record instances if possible.
    items, failed = collect_records(*ids, force: force)
    return [], failed if atomic && failed.present? || items.blank?

    # Batching occurs unconditionally in order to ensure that the requested
    # items can be successfully removed from the index.
    opt[:requests] ||= {} if repo_remove
    opt.merge!(index: index, atomic: atomic, force: force)
    succeeded, failed = batch_upload_operation(:upload_remove, items, **opt)

    # After all batch operations have completed, truncate the database table
    # (i.e., so that the next entry starts with id == 1) if appropriate.
    if truncate_delete && (ids == %w(*))
      if failed.present?
        Log.warn('database not truncated due to the presence of errors')
      else
        Upload.connection.truncate(Upload.table_name)
      end
    end

    # Member repository removal requests that were deferred in #upload_remove
    # are handled now.
    if repo_remove && opt[:requests].present?
      if atomic && failed.present?
        Log.warn('failure(s) prevented generation of repo removal requests')
      else
        requests = opt.delete(:requests)
        s, f = batch_repository_remove(requests, **opt)
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
  # @param [Array<String,Integer,Hash,Upload>] entries
  # @param [Integer, Boolean]                  size     Default: #BATCH_SIZE.
  # @param [Hash]                              opt
  #
  # @return [(Array,Array)]   Succeeded records and failed item messages.
  #
  def batch_upload_operation(op, entries, size: nil, **opt)
    __debug_items((dbg = "UPLOAD WF #{op}"), binding)
    opt[:bulk] ||= { total: entries.size }

    # Set batch size for this iteration.
    size = batch_size     if size.nil?
    size = -1             if size.is_a?(FalseClass)
    size =  0             if size.is_a?(TrueClass)
    size = size.to_i
    size = entries.size   if size.negative?
    size = BATCH_SIZE     if size.zero?
    size = MAX_BATCH_SIZE if size > MAX_BATCH_SIZE

    succeeded = []
    failed    = []
    counter   = 0
    entries.each_slice(size) do |batch|
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
  def throttle(counter, frequency: 1, pause: true)
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
  # @raise [RuntimeError]             If *item* not found and !*no_raise*.
  #
  # @return [Upload]                  The item; from the database if necessary.
  # @return [nil]                     If *item* not found and *no_raise*.
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def get_record(id, no_raise: false, meth: nil)
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
  def find_records(*items, **opt)
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
  #--
  # noinspection RubyNilAnalysis
  #++
  def new_record(data = nil)
    __debug_items("UPLOAD WF #{__method__}", binding)
    Upload.new(data).tap { |record| add_title_prefix(record) if title_prefix }
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
  # @return [(Array<Upload>,Array)]       Upload records and failed ids.
  # @return [(Array<Upload,String>,[])]   If *force* is *true*.
  #
  # == Usage Notes
  # If *force* is true, the returned list of failed records will be empty but
  # the returned list of items may contain a mixture of Upload and String
  # elements.
  #
  def collect_records(*items, all: false, force: false, **opt)
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
  def add_title_prefix(record, prefix: title_prefix)
    return if prefix.blank?
    return if (title = record&.active_emma_metadata[:dc_title]).nil?
    prefix = "#{prefix} - " unless prefix.match?(/[[:punct:]]\s*$/)
    prefix = "#{prefix} "   unless prefix.end_with?(' ')
    return if title.start_with?(prefix)
    record.modify_active_emma_data(dc_title: "#{prefix}#{title}")
  end

  # ===========================================================================
  # :section: Storage
  # ===========================================================================

  protected

  # Upload file via Shrine.
  #
  # @param [ActionDispatch::Request, Hash] opt
  #
  # @option opt [Rack::Request::Env] :env
  #
  # @return [(Integer, Hash{String=>*}, Array<String>)]
  #
  # @see Shrine::Plugins::UploadEndpoint::ClassMethods#upload_response
  #
  def upload_file(**opt)
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
  # @return [Upload]                  The provided or created record.
  # @return [nil]                     If the record was not created or updated.
  #
  def db_insert(data)
    __debug_items("UPLOAD WF #{__method__}", binding)
    record = data.is_a?(Upload) ? data : new_record(data)
    record.save if record&.new_record?
    # noinspection RubyYardReturnMatch
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
  def db_update(record, data = nil)
    __debug_items("UPLOAD WF #{__method__}", binding)
    record, data = [nil, record] if record.is_a?(Hash)
    unless record.is_a?(Upload)
      if data.is_a?(Hash)
        opt, data = partition_hash(data, :no_raise, :meth)
        ids, data = partition_hash(data, :id, :submission_id)
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
    # noinspection RubyYardReturnMatch
    record
  end

  # Remove a single existing Upload record from the database.
  #
  # @param [Upload, Hash, String] data
  #
  # @return [Any]
  # @return [nil]                     If the record was not found or removed.
  #
  def db_delete(data)
    __debug_items("UPLOAD WF #{__method__}", binding)
    record = data.is_a?(Upload) ? data : get_record(data)
    record&.destroy
  end

  # ===========================================================================
  # :section: Index ingest
  # ===========================================================================

  public

  # As a convenience for testing, sending to the Federated Search Ingest API
  # can be short-circuited here.  The value should be *false* normally.
  #
  # @type [Boolean]
  #
  DISABLE_UPLOAD_INDEX_UPDATE = true?(ENV['DISABLE_UPLOAD_INDEX_UPDATE'])

  # Add the indicated items from the EMMA Unified Index.
  #
  # @param [Array<Upload>] items
  # @param [Boolean]       atomic
  #
  # @raise [Api::Error] @see IngestService::Request::Records#put_records
  #
  # @return [(Array,Array,Array)]     Succeeded records, failed item messages,
  #                                     and records to roll back.
  #
  def add_to_index(*items, atomic: true, **)
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
  # @raise [Api::Error] @see IngestService::Request::Records#put_records
  #
  # @return [(Array,Array,Array)]     Succeeded records, failed item messages,
  #                                     and records to roll back.
  #
  def update_in_index(*items, atomic: true, **)
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
  # @raise [Api::Error] @see IngestService::Request::Records#delete_records
  #
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  def remove_from_index(*items, atomic: true, **)
    __debug_items("UPLOAD WF #{__method__}", binding)
    items = normalize_index_items(*items, meth: __method__)
    return [], [] if items.blank?

    result = ingest_api.delete_records(*items)
    succeeded, failed, _ = process_ingest_errors(result, *items)
    succeeded = [] if atomic && failed.present?
    return succeeded, failed
  end

  # Override the normal methods if Unified Search update is disabled.

  if DISABLE_UPLOAD_INDEX_UPDATE

    %i[add_to_index update_in_index remove_from_index].each do |m|
      send(:define_method, m) { |*items, **| skip_index_ingest(m, *items) }
    end

    def skip_index_ingest(meth, *items)
      __debug { "** SKIPPING ** UPLOAD #{meth} | items = #{items.inspect}" }
      return items, []
    end

  end

  # ===========================================================================
  # :section: Index ingest
  # ===========================================================================

  protected

  # Error key prefix which indicates a general (non-item-specific) error
  # message entry.
  #
  # @type [String]
  #
  GENERAL_ERROR_TAG = Api::Shared::ErrorTable::GENERAL_ERROR_TAG

  # Interpret error message(s) generated by Federated Ingest to determine which
  # item(s) failed.
  #
  # @param [Ingest::Message::Response, Hash{String,Integer=>String}] result
  # @param [Array<Upload, String>]                                   items
  #
  # @return [(Array,Array,Array)]     Succeeded records, failed item messages,
  #                                     and records to roll back.
  #
  # @see Api::Shared::ErrorTable#make_error_table
  #
  # == Implementation Notes
  # It's not clear whether there would ever be situations where there was a mix
  # of errors by index, errors by submission ID, and/or general errors, but
  # this method was written to be able to cope with the possibility.
  #
  def process_ingest_errors(result, *items)
    # If there were no errors then indicate that all items succeeded.
    errors = result.is_a?(Ingest::Message::Response) ? result.errors : result
    return items, [], [] if errors.blank?

    # Otherwise, all items will be assumed to have failed.
    rollback  = items
    sids      = []
    failed    = []
    succeeded = []

    # Errors associated with the position of the item in the request.
    by_index = errors.select { |k| k.is_a?(Integer) }
    if by_index.present?
      by_index.transform_keys! { |idx| Upload.sid_for(items[idx-1]) }
      sids   += by_index.keys
      failed += by_index.map { |sid, msg| ErrorEntry.new(sid, msg) }
      errors.except!(*by_index.keys)
    end

    # Errors associated with item submission ID.
    by_sid = errors.reject { |k| k.start_with?(GENERAL_ERROR_TAG) }
    if by_sid.present?
      sids   += by_sid.keys
      failed += by_sid.map { |sid, msg| ErrorEntry.new(sid, msg) }
      errors.except!(*by_sid.keys)
    end

    # Remaining (general) errors indicate that there was a problem with the
    # request and that all items have failed.
    if errors.present?
      failed += errors.values.map { |msg| ErrorEntry.new(msg) }
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
  #
  # @raise [SubmitError] If the number of items is too large to be ingested.
  #
  # @return [Array]
  #
  def normalize_index_items(*items, meth: nil)
    items = items.flatten.compact
    return items unless items.size > INGEST_MAX_SIZE
    error = [meth, 'item count', "#{item.size} > #{INGEST_MAX_SIZE}"]
    error = error.compact.join(': ')
    Log.error(error)
    failure(error)
  end

  # ===========================================================================
  # :section: Member repository requests
  # ===========================================================================

  public

  # Failure messages for member repository requests. # TODO: I18n
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

  # Submit a new item to member repository.
  #
  # @param [String]        repo
  # @param [Array<Upload>] data
  # @param [Hash]          opt
  #
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  def repository_create(repo, *data, **opt)
    succeeded = []
    failed    = []
    if repo.blank?
      failed << REPO_FAILURE[:no_repo]
    elsif data.blank?
      failed << REPO_FAILURE[:no_items]
    elsif !repo_create
      failed << REPO_FAILURE[:no_create]
    else
      result = aws_api.creation_request(*data, **opt)
      succeeded, failed = process_aws_errors(result, *data)
    end
    return succeeded, failed
  end

  # Request a change to a prior submission to a member repository.
  #
  # @param [String]        repo
  # @param [Array<Upload>] data
  # @param [Hash]          opt
  #
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  # @note Not currently supported by any member repository.
  #
  def repository_edit(repo, *data, **opt)
    succeeded = []
    failed    = []
    if repo.blank?
      failed << REPO_FAILURE[:no_repo]
    elsif data.blank?
      failed << REPO_FAILURE[:no_items]
    elsif !repo_edit
      failed << REPO_FAILURE[:no_edit]
    else
      result = aws_api.modification_request(*data, **opt)
      succeeded, failed = process_aws_errors(result, *data)
    end
    return succeeded, failed
  end

  # Request deletion of a prior submission to a member repository.
  #
  # @param [String]               repo
  # @param [Array<String,Upload>] data
  # @param [Hash]                 opt
  #
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  # @note Not currently supported by any member repository.
  #
  def repository_remove(repo, *data, **opt)
    succeeded = []
    failed    = []
    if repo.blank?
      failed << REPO_FAILURE[:no_repo]
    elsif data.blank?
      failed << REPO_FAILURE[:no_items]
    elsif opt[:emergency]
      # Emergency override for deleting bogus entries creating during
      # testing/development.
      succeeded, failed = remove_from_index(*data)
    elsif !repo_remove
      failed << REPO_FAILURE[:no_remove]
    else
      result = aws_api.removal_request(*data, **opt)
      succeeded, failed = process_aws_errors(result, *data)
    end
    return succeeded, failed
  end

  # ===========================================================================
  # :section: Member repository requests
  # ===========================================================================

  protected

  # Interpret error message(s) generated by AWS S3.
  #
  # @param [AwsS3::Message::Response, Hash{String,Integer=>String}] result
  # @param [Array<String, Upload>]                                  data
  #
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  # @see Api::Shared::ErrorTable#make_error_table
  #
  def process_aws_errors(result, *data)
    errors = result.is_a?(AwsS3::Message::Response) ? result.errors : result
    if errors.blank?
      return data, []
    else
      return [], errors.values.map { |msg| ErrorEntry.new(msg) }
    end
  end

  # ===========================================================================
  # :section: Member repository requests
  # ===========================================================================

  public

  # batch_repository_remove
  #
  # @param [Hash, Array] items
  # @param [Hash]        opt          Passed to #repository_remove.
  #
  # @return [(Array,Array)]           Succeeded items and failed item messages.
  #
  # == Variations
  #
  # @overload batch_repository_remove(requests, **opt)
  #   @param [Hash{Symbol=>Array}]            requests
  #   @param [Hash]                           opt
  #   @return [(Array,Array)]
  #
  # @overload batch_repository_remove(items, **opt)
  #   @param [Array<String,#emma_recordId,*>] items
  #   @param [Hash]                           opt
  #   @return [(Array,Array)]
  #
  def batch_repository_remove(items, **opt)
    succeeded = []
    failed    = []
    batch_repository_request(items).each_pair do |repo, repo_items|
      repo_items.map! { |item| Upload.record_id(item) }
      s, f = repository_remove(repo, *repo_items, **opt)
      succeeded += s
      failed    += f
    end
    return succeeded, failed
  end

  # batch_repository_request
  #
  # @param [Hash, Array] items
  # @param [Boolean]     empty_key    If *true*, allow invalid items.
  #
  # @return [Hash{String=>Array}]
  #
  # == Variations
  #
  # @overload batch_repository_request(requests)
  #   @param [Hash{String=>Array}] requests
  #   @return [Hash{String=>Array}]
  #
  # @overload batch_repository_request(items)
  #   @param [Array<String,#emma_recordId,*>] items
  #   @return [Hash{String=>Array}]
  #
  def batch_repository_request(items, empty_key: false)
    result = {}
    case items
      when Array
        items  = items.flatten.compact_blank
        result = items.group_by { |item| Upload.repository_of(item) }
      when Hash
        result = items.transform_values { |repo_items| Array.wrap(repo_items) }
      else
        Log.error { "#{__method__}: expected 'items' type: #{items.class}" }
    end
    # noinspection RubyYardReturnMatch
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
    force = force_delete
    items = Upload.expand_ids(*event_args.flatten.compact)
    emma_items, repo_items = items.partition { |item| emma_item?(item) }

    # EMMA items and/or EMMA submission ID's.
    opt = { no_raise: force }
    self.succeeded += emma_items.map { |item| get_record(item, **opt) || item }

    if repo_items.present?
      if force && repo_remove
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
    opt = event_args.extract_options!&.dup || {}
    opt[:force]     = force_delete     unless opt.key?(:force)
    opt[:emergency] = emergency_delete unless opt.key?(:emergency)
    opt[:truncate]  = truncate_delete  unless opt.key?(:truncate)
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
class UploadWorkflow < Workflow::Base

  include UploadWorkflow::Events
  include UploadWorkflow::States
  include UploadWorkflow::Transitions

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
  # This method overrides:
  # @see Workflow::ClassMethods#workflow_column
  #
  def self.workflow_column(*)
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
        @configuration ||= super
      end

      # Workflow state labels.
      #
      # @return [Hash{Symbol=>Hash}]
      #
      def self.state_label
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
        @workflow_type ||= super
      end

      # Table of variant workflow types under this workflow base class.
      #
      # @return [Hash{Symbol=>Class<UploadWorkflow>}]
      #
      def self.variant_table
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
          # noinspection RailsParamDefResolve
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
          # This method overrides:
          # @see Workflow::ClassMethods#workflow_column
          #
          def self.workflow_column(*)
            @workflow_state_column_name ||=
              safe_const_get(:STATE_COLUMN) || super
          end

          # Return the variant subclass type.
          #
          # @return [Symbol]
          #
          # This method overrides:
          # @see Workflow::Base#variant_type
          #
          def self.variant_type
            @variant_type ||= name.demodulize.to_s.underscore.to_sym
          end

        end

      end

    end

  end

end

__loading_end(__FILE__)
