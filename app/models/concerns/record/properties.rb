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
  TITLE_PREFIX = (DEV_TITLE_PREFIX if not_deployed?)

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
  FORCE_DELETE_DEFAULT = true

  # Force deletions of EMMA Unified Index entries even if the record ID does
  # not begin with "emma-".  (This is to support development during which
  # sometimes fake member repository entries get into the index.)
  #
  # When *false*, only items with :emma_repositoryRecordId values beginning
  # with "emma-" will be submitted to the EMMA Unified Ingest service.  All
  # others will result in generating a request for consideration by the member
  # repository.
  #
  # When *true*, all items will be submitted to the Unified Ingest service.
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
  # When *false*, do not truncate the "entries" table.
  #
  # When *true*, truncate the "entries" table, resetting the initial ID to 1.
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
  #--
  # noinspection RubyMismatchedConstantType
  #++
  BATCH_SIZE = [
    ENV['BATCH_SIZE']&.to_i,
    BATCH_SIZE_DEFAULT,
    MAX_BATCH_SIZE,
    BATCH_UPPER_BOUND,
  ].compact.min

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
  # @see #FORCE_DELETE_DEFAULT
  #
  def force_delete
    key = OPTION_PARAMETER_MAP[__method__]
    parameter_setting(key)
  end

  # Force deletions of EMMA Unified Index entries even if the record ID does
  # not begin with "emma-".  (This is to support development during which
  # sometimes fake member repository entries get into the index.)
  #
  # @return [Boolean]
  #
  # @see #EMERGENCY_DELETE_DEFAULT
  #
  def emergency_delete
    key = OPTION_PARAMETER_MAP[__method__]
    parameter_setting(key)
  end

  # If all "entries" records are removed, reset the next ID to 1.
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
  # @return [Hash{Symbol=>Any}]
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
    case value
      when true, false then value
      when nil         then default
      else                  default ? !false?(value) : true?(value)
    end
  end

end

__loading_end(__FILE__)
