# app/models/phase/_bulk_operation.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# == Phase::BulkOperation
#
# Base class for phases that represent bulk operations.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.phase.bulk_operation*
#
# @!method started?
# @!method running?
# @!method pausing?
# @!method resuming?
# @!method restarting?
# @!method completed?
# @!method canceling?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method running!
# @!method pausing!
# @!method resuming!
# @!method restarting!
# @!method completed!
# @!method canceling!
# @!method canceled!
# @!method aborted!
#
class Phase::BulkOperation < Phase

  include Record::Bulk::Operation
  include Record::Steppable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Source of the file to be uploaded.                                          # NOTE: from Upload::BulkMethods
  #
  # @return [String, nil]
  #
  attr_reader :manifest_path

  # Source of the file to be uploaded.
  #
  # @return [Array, nil]
  #
  attr_reader :manifest

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, ActionController::Parameters, Model, nil] attr
  # @param [Hash, nil]                                      opt
  # @param [Proc, nil]                                      block
  #
  # @option attr [String|Array] :manifest   If *attr* is a Hash or Hash-like.
  # @option opt  [String|Array] :manifest   If *opt* hash is provided.
  #
  def initialize(attr = nil, opt = nil, &block)
    data = (opt[:manifest] if opt.is_a?(Hash))
    if attr && !attr.is_a?(ApplicationRecord) && attr.key?(:manifest)
      data ||= attr[:manifest]
      attr = attr.except(:manifest)
    end
    super(attr, &block)
    load_manifest(data) if data
  end

  # ===========================================================================
  # :section: Record::Sti overrides
  # ===========================================================================

  public

  # The #type_value of BulkPart elements associated with this BulkOperation.
  #
  # @return [Symbol, nil]
  #
  def base_type_value
    bulk_type&.underscore&.to_sym
  end

  # The #type_value of BulkPart elements associated with this BulkOperation.
  #
  # @return [Symbol, nil]
  #
  def self.base_type_value
    bulk_type&.underscore&.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Source of the file to be uploaded.
  #
  # @return [Array]
  #
  def manifest
    @manifest ||= load_manifest
  end

  # load_manifest
  #
  # @param [String, Array, nil] data
  #
  # @return [Array]
  #
  def load_manifest(data = nil)
    data ||= @manifest_path
    case data
      when String
        @manifest_path = data
        @manifest = []
        # TODO: extract into @manifest ...
      when Array
        @manifest_path = nil
        @manifest = data.dup
      else
        raise "#{__method__}: #{data.class}: type unexpected"
    end
    @manifest
  end

  # ===========================================================================
  # :section: Record::Controllable::CommandMethods overrides
  # ===========================================================================

  public

  # Perform bulk operation.
  #
  # @param [Hash] opt
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  # @see Record::Controllable#COMMAND_TABLE[:run]
  #
  def run!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    # @type [Symbol]
    prev_state = transition_to(:running, **opt) or return
    super
    run_sequence(prev_state, **opt) or return revert_to!(prev_state)
    run_callback(**opt)
  end

  # Pause running action(s).
  #
  # @param [Hash] opt
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  # @see Record::Controllable#COMMAND_TABLE[:pause]
  #
  def pause!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    # @type [Symbol]
    prev_state = transition_to(:pausing, **opt) or return
    super
    pause_sequence(prev_state, **opt) or return revert_to!(prev_state)
    run_callback(**opt)
  end

  # Resume paused action(s).
  #
  # @param [Hash] opt
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  # @see Record::Controllable#COMMAND_TABLE[:resume]
  #
  def resume!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    # @type [Symbol]
    prev_state = transition_to(:resuming, **opt) or return
    super
    resume_sequence(prev_state, **opt) or return revert_to!(prev_state)
    running!
    run_callback(**opt)
  end

  # Retry failed action(s).
  #
  # @param [Hash] opt
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  # @see Record::Controllable#COMMAND_TABLE[:restart]
  #
  def restart!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    # @type [Symbol]
    prev_state = transition_to(:restarting, **opt) or return
    super
    restart_sequence(prev_state, **opt) or return revert_to!(prev_state)
    running!
    run_callback(**opt)
  end

  # ===========================================================================
  # :section: Record::Controllable::CommandMethods overrides
  # ===========================================================================

  protected

  # Transition to a previous state unconditionally.
  #
  # @param [Symbol, String] prev_state
  #
  # @return [nil]
  #
  def revert_to!(prev_state)
    send("#{prev_state}!")
    nil
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The subclass-specific operation(s) performed when running.
  #
  # @param [Symbol, Any] prev_state
  # @param [Hash]        opt
  #
  # @return [Boolean]
  #
  def run_sequence(prev_state = nil, **opt)
    not_implemented "not defined by #{self.class}"
  end

  # The operation(s) performed when pausing.
  #
  # @param [Symbol, Any] prev_state
  # @param [Hash]        opt
  #
  # @return [Boolean]
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def pause_sequence(prev_state = nil, **opt)
    succeeded = false # TODO: BulkOperation#pause_sequence
    aborted! unless succeeded
    succeeded
  end

  # The operation(s) performed when resuming.
  #
  # @param [Symbol, Any] prev_state
  # @param [Hash]        opt
  #
  # @return [Boolean]
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def resume_sequence(prev_state = nil, **opt)
    succeeded = false # TODO: BulkOperation#resume_sequence
    aborted! unless succeeded
    succeeded
  end

  # The operation(s) performed when restarting.
  #
  # @param [Symbol, Any] prev_state
  # @param [Hash]        opt
  #
  # @return [Boolean]
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def restart_sequence(prev_state = nil, **opt)
    succeeded = false # TODO: BulkOperation#restart_sequence
    aborted! unless succeeded
    succeeded
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @param [Phase, nil] phase
  # @param [Hash]       opt
  #
  # @return [String]
  #
  def self.describe_type(phase, **opt)
    "BULK #{phase&.bulk_type || bulk_type}".upcase # TODO: I18n
  end

  # A textual description of the status of the given Phase instance.
  #
  # @param [Phase] phase
  # @param [Hash]  opt
  #
  # @return [String]
  #
  def self.describe_status(phase, **opt)
    opt[:note] ||= describe_type(phase, **opt)
    opt[:note]   = "#{opt[:note]} [%{parts}]"
    super(phase, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  validate_state_table if sanity_check?

end

__loading_end(__FILE__)
