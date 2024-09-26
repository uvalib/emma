# app/models/concerns/record/properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# @note From UploadWorkflow::Properties
module Record::Properties

  # ===========================================================================
  # :section: Constants
  # ===========================================================================

  public

  # The EMMA Unified Ingest API cannot accept more than 1000 items; this puts a
  # hard upper-bound on batch sizes and the size of input values that certain
  # methods can accept.
  #
  # @type [Integer]
  #
  INGEST_MAX_SIZE = ENV_VAR['INGEST_MAX_SIZE'].to_i

  # A string added to the start of each title created on a non-production
  # instance to help distinguish it from other index results.
  #
  # @type [String]
  #
  UPLOAD_DEV_TITLE_PREFIX = ENV_VAR['UPLOAD_DEV_TITLE_PREFIX'] || ''

  # A string added to the start of each title.
  #
  # This should normally be *nil*.
  #
  # @type [String, nil]
  #
  # @see #title_prefix
  #
  TITLE_PREFIX = (UPLOAD_DEV_TITLE_PREFIX if not_deployed?)

  # A fractional number of seconds to pause between iterations.
  #
  # If *false* or *nil* then throttling will not occur.
  #
  # @type [Float, FalseClass, nil]
  #
  BULK_THROTTLE_PAUSE = ENV_VAR['BULK_THROTTLE_PAUSE']&.try(:to_f)

  # ===========================================================================
  # :section: Property defaults
  # ===========================================================================

  public

  # Force deletions of EMMA Unified Index entries regardless of whether the
  # item is in the "entries" table.
  #
  # When *false*, items that cannot be found in the "entries" table are treated
  # as failures.
  #
  # When *true*, items identified by submission ID will be included in the
  # argument list to #remove_from_index unconditionally.
  #
  # @type [Boolean]
  #
  # @see #force_delete
  #
  UPLOAD_FORCE_DELETE = true?(ENV_VAR['UPLOAD_FORCE_DELETE'])

  # Force deletions of EMMA Unified Index entries even if the record ID does
  # not begin with "emma-".  (This is to support development during which
  # sometimes fake partner repository entries get into the index.)
  #
  # When *false*, only items with :emma_repositoryRecordId values beginning
  # with "emma-" will be submitted to the EMMA Unified Ingest service.  All
  # others will result in generating a request for consideration by the partner
  # repository.
  #
  # When *true*, all items will be submitted to the Unified Ingest service.
  #
  # @type [Boolean]
  #
  # @see #emergency_delete
  #
  UPLOAD_EMERGENCY_DELETE = true?(ENV_VAR['UPLOAD_EMERGENCY_DELETE'])

  # For the special case of deleting all records (effectively wiping the
  # database) this controls whether the next available ID should be set to 1.
  #
  # Otherwise, the next record after removing all records will have an 'id'
  # which is 1 greater than the last record prior to the deletion.
  #
  # When *false*, do not truncate the "entries" table.
  #
  # When *true*, truncate the "entries" table, resetting the initial ID to 1.
  #
  # @type [Boolean]
  #
  UPLOAD_TRUNCATE_DELETE = true?(ENV_VAR['UPLOAD_TRUNCATE_DELETE'])

  # For the "partner repository workflow", permit the **creation** of partner
  # repository items via a request to be queued to a partner repository.
  #
  # @type [Boolean]
  #
  UPLOAD_REPO_CREATE = true?(ENV_VAR['UPLOAD_REPO_CREATE'])

  # For the "partner repository workflow", permit the **update** of partner
  # repository items via a request to be queued to a partner repository.
  #
  # @type [Boolean]
  #
  UPLOAD_REPO_EDIT = true?(ENV_VAR['UPLOAD_REPO_EDIT'])

  # For the "partner repository workflow", permit the **removal** of partner
  # repository items via a request to be queued to a partner repository.
  #
  # @type [Boolean]
  #
  UPLOAD_REPO_REMOVE = true?(ENV_VAR['UPLOAD_REPO_REMOVE'])

  # Default size for batching.
  #
  # @type [Integer]
  #
  BATCH_SIZE_DEFAULT = 10

  # Batches larger than this number are not possible.
  #
  # @type [Integer]
  #
  BATCH_UPPER_BOUND = INGEST_MAX_SIZE - 1

  # Batches larger than this number are not permitted.
  #
  # @type [Integer]
  #
  MAX_BATCH_SIZE = BATCH_UPPER_BOUND

  # Break sets of submissions into chunks of this size.
  #
  # This is the value returned by #batch_size unless a different size was
  # explicitly given via the :batch URL parameter.
  #
  # @type [Integer]
  #
  BATCH_SIZE = [
    ENV_VAR['BATCH_SIZE']&.to_i,
    BATCH_SIZE_DEFAULT,
    BATCH_UPPER_BOUND,
    MAX_BATCH_SIZE,
  ].compact.min

  # URL parameter names and default values.
  #
  # @type [Hash{Symbol=>any}]
  #
  OPTION_PARAMETER_DEFAULT = {
    prefix:       TITLE_PREFIX,
    batch:        BATCH_SIZE,
    force:        UPLOAD_FORCE_DELETE,
    emergency:    UPLOAD_EMERGENCY_DELETE,
    truncate:     UPLOAD_TRUNCATE_DELETE,
    repo_create:  UPLOAD_REPO_CREATE,
    repo_edit:    UPLOAD_REPO_EDIT,
    repo_remove:  UPLOAD_REPO_REMOVE,
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
  # :section:
  # ===========================================================================

  if sanity_check?
    unless (BATCH_SIZE_DEFAULT..1000).include?((v = INGEST_MAX_SIZE))
      raise "Invalid INGEST_MAX_SIZE: #{v.class} #{v.inspect}"
    end
    unless [nil, false].include?((v = BULK_THROTTLE_PAUSE))
      invalid = !v.is_a?(Numeric) || v.negative?
      raise "Invalid BULK_THROTTLE_PAUSE: #{v.class} #{v.inspect}" if invalid
    end
  end

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
  # === Usage Notes
  # The prefix cannot match any of #TRUE_VALUES or #FALSE_VALUES.
  #
  def title_prefix
    key   = OPTION_PARAMETER_MAP[__method__]
    value = parameters[key]
    return false if false?(value)
    value = nil  if true?(value)
    value&.to_s || OPTION_PARAMETER_DEFAULT[key]
  end

  # Force deletions of EMMA Unified Index entries regardless of whether the
  # item is in the "entries" table.
  #
  # @return [Boolean]
  #
  # @see #UPLOAD_FORCE_DELETE
  #
  def force_delete
    key = OPTION_PARAMETER_MAP[__method__]
    parameter_setting(key)
  end

  # Force deletions of EMMA Unified Index entries even if the record ID does
  # not begin with "emma-".  (This is to support development during which
  # sometimes fake partner repository entries get into the index.)
  #
  # @return [Boolean]
  #
  # @see #UPLOAD_EMERGENCY_DELETE
  #
  def emergency_delete
    key = OPTION_PARAMETER_MAP[__method__]
    parameter_setting(key)
  end

  # If all "entries" records are removed, reset the next ID to 1.
  #
  # @return [Boolean]
  #
  # @see #UPLOAD_TRUNCATE_DELETE
  #
  def truncate_delete
    key = OPTION_PARAMETER_MAP[__method__]
    parameter_setting(key)
  end

  # For the "partner repository workflow", permit the **creation** of partner
  # repository items via a request to be queued to a partner repository.
  #
  # @return [Boolean]
  #
  # @see #UPLOAD_REPO_CREATE
  #
  def repo_create
    key = OPTION_PARAMETER_MAP[__method__]
    # TODO: conditionally accept repo_create based on user?
    OPTION_PARAMETER_DEFAULT[key]
  end

  # For the "partner repository workflow", permit the **update** of partner
  # repository items via a request to be queued to a partner repository.
  #
  # @return [Boolean]
  #
  # @see #UPLOAD_REPO_EDIT
  #
  def repo_edit
    key = OPTION_PARAMETER_MAP[__method__]
    # TODO: conditionally accept repo_edit based on user?
    OPTION_PARAMETER_DEFAULT[key]
  end

  # For the "partner repository workflow", permit the **removal** of partner
  # repository items via a request to be queued to a partner repository.
  #
  # @return [Boolean]
  #
  # @see #UPLOAD_REPO_REMOVE
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
  # EntryConcern) or in the context of the workflow instance (through the
  # parameters saved from the :params initializer option).
  #
  # @return [Hash]
  #
  # @see ::Options#model_params
  #
  def parameters
    # noinspection RailsParamDefResolve
    try(:model_params) || try(:params) || {}
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
  # === Implementation Notes
  # If *default* is *false* then *true* is returned only if *value* is "true".
  # If *default* is *true* then *false* is returned only if *value* is "false".
  #
  def parameter_setting(key, prm = nil)
    prm   ||= parameters
    value   = prm&.dig(key)
    default = OPTION_PARAMETER_DEFAULT[key]
    # noinspection RubyMismatchedReturnType
    case value
      when true, false then value
      when nil         then default
      else                  default ? !false?(value) : true?(value)
    end
  end

end

__loading_end(__FILE__)
