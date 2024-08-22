# app/models/workflow.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'workflow'

# Base class for workflow types.
#
# NOTE: This is placed into the Workflow namespace set up by the workflow gem.
#
# NOTE: Since the workflow gem is geared toward pre-Ruby-3 handling of options,
#   none of the methods for this and related classes/modules assume options are
#   passed as the final element of *args (rather than via keyword arguments).
#
class Workflow::Base

  include Workflow

  # Even if workflow debugging is enabled, displaying transition hooks may be
  # too noisy.
  #
  # @type [Boolean]
  #
  DEBUG_TRANSITION = DEBUG_WORKFLOW && false

  # Root workflow configuration.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  CONFIGURATION = config_section(:workflow).deep_freeze

  # The state which indicates that the item associated with the workflow has
  # progressed to the end.
  #
  # @type [Symbol]
  #
  FINAL_STATE = :completed

end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

# Classes of users recognized within *workflow* definitions.
#
# @note TODO: harmonize with existing roles
#
module Workflow::Base::Roles

  # The default workflow role if none was given.
  #
  # @type [Symbol]
  #
  DEFAULT_WF_ROLE = application_deployed? ? :system_wf : :developer_wf

  # Workflow roles.
  #
  # NOTE: These roles do not necessarily map directly on to the authorization
  #   roles used elsewhere in the system.  At some point these need to be
  #   harmonized -- perhaps at the point that reliance on the 'workflow' gem is
  #   removed in favor of a more integrated approach.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  WF_ROLE = {
    user_wf:      %i[submitter_wf],
    submitter_wf: [],
    reviewer_wf:  [],
    admin_wf:     %i[submitter_wf reviewer_wf],
    system_wf:    %i[submitter_wf reviewer_wf admin_wf],
    developer_wf: %i[user_wf submitter_wf reviewer_wf admin_wf system_wf],
  }.map { |primary, roles|
    roles = [primary, *roles].uniq
    [primary, roles]
  }.to_h.deep_freeze

  # ===========================================================================
  # :section: Workflow event definition options
  # ===========================================================================

  public

  IF_USER       = { if: ->(wf) { wf.user_wf? } }.freeze
  IF_SUBMITTER  = { if: ->(wf) { wf.submitter_wf? } }.freeze
  IF_REVIEWER   = { if: ->(wf) { wf.reviewer_wf? } }.freeze
  IF_ADMIN      = { if: ->(wf) { wf.admin_wf? } }.freeze
  IF_SYSTEM     = { if: ->(wf) { wf.system_wf? } }.freeze
  IF_DEV        = { if: ->(wf) { wf.developer_wf? } }.freeze

  IF_SYS_DEBUG  = { if: ->(wf) { DEBUG_WORKFLOW && wf.system_wf? } }.freeze
  IF_DEV_DEBUG  = { if: ->(wf) { DEBUG_WORKFLOW && wf.developer_wf? } }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The current workflow user.
  #
  # @return [User,String]
  #
  def wf_user
    @wf_user ||= set_wf_user
  end

  # The workflow role of the current workflow user.
  #
  # @return [Symbol]
  #
  def wf_role
    @wf_role ||= set_wf_role
  end

  # Set the workflow user.
  #
  # @param [User, String, Symbol, nil] user
  #
  # @return [User, String]
  #
  def set_wf_user(user = nil)
    role = set_wf_role(user)
    user = role.to_s if user.nil? || user.is_a?(Symbol)
    # noinspection RubyMismatchedReturnType
    @wf_user = user
  end

  # Set the workflow role for the current workflow user.
  #
  # @param [User, String, Symbol, nil] role
  #
  # @return [Symbol]
  #
  def set_wf_role(role = nil)
    @wf_role = get_wf_role(role) || DEFAULT_WF_ROLE
  end

  # Get the workflow role of the given identity.
  #
  # @param [any, nil] user            User, String, Symbol
  #
  # @return [Symbol, nil]
  #
  def get_wf_role(user)
    return user if user.is_a?(Symbol)
    user = User.instance_for(user)
    user.developer? ? :developer_wf : :user_wf if user
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the instance is associated with a user acting in the
  # capacity of a submitter.
  #
  # @param [User, String, Symbol, nil] u    @see #wf_roles
  #
  def user_wf?(u = nil)
    wf_roles(u).include?(:user_wf)
  end

  # Indicate whether the instance is associated with a user acting in the
  # capacity of a submitter.
  #
  # @param [User, String, Symbol, nil] u    @see #wf_roles
  #
  def submitter_wf?(u = nil)
    wf_roles(u).include?(:submitter_wf)
  end

  # Indicate whether the instance is associated with a user acting in the
  # capacity of a reviewer.
  #
  # @param [User, String, Symbol, nil] u    @see #wf_roles
  #
  def reviewer_wf?(u = nil)
    wf_roles(u).include?(:reviewer_wf)
  end

  # Indicate whether the instance is associated with an administrator user or
  # process.
  #
  # @param [User, String, Symbol, nil] u    @see #wf_roles
  #
  def admin_wf?(u = nil)
    wf_roles(u).include?(:admin_wf)
  end

  # Indicate whether the instance is associated with the system process.
  #
  # @param [User, String, Symbol, nil] u    @see #wf_roles
  #
  def system_wf?(u = nil)
    wf_roles(u).include?(:system_wf)
  end

  # Indicate whether the instance is associated with a developer.
  #
  # @param [User, String, Symbol, nil] u    @see #wf_roles
  #
  def developer_wf?(u = nil)
    wf_roles(u).include?(:developer_wf)
  end

  # The workflow role(s) for the given user.
  #
  # @param [User, String, Symbol, nil] u    Default: #wf_user
  #
  # @return [Array<Symbol>]
  #
  # @see #WF_ROLE
  #
  def wf_roles(u = nil)
    primary = get_wf_role(u) || wf_role
    WF_ROLE[primary] || Array.wrap(primary)
  end

end

# Support for workflow properties that can be set via URL parameters.
#
module Workflow::Base::Properties

  # URL parameters passed in through the constructor.
  #
  # @return [Hash]
  #
  attr_accessor :parameters

end

# =============================================================================
# :section: Core
# =============================================================================

public

module Workflow::Base::External

  # Model/controller options passed in through the constructor.
  #
  # @return [Upload::Options]
  #
  attr_reader :model_options

end

# Workflow execution status information.
#
module Workflow::Base::Data

  include Workflow::Base::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Succeeded items.
  #
  # @return [Array]
  #
  attr_accessor :succeeded

  # Failed items.
  #
  # @return [Array]
  #
  attr_accessor :failures

  # The characteristic "return value" of the workflow after an event has been
  # registered.
  #
  # @return [any, nil]
  #
  attr_accessor :results

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # set_data
  #
  # @param [any, nil] data
  # @param [Boolean]  reset
  #
  # @return [any, nil]
  #
  def set_data(data, reset: true, **)
    reset_status if reset
    data
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # reset_status
  #
  # @return [void]
  #
  def reset_status(...)
    self.succeeded = []
    self.failures  = []
    self.results   = nil
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether data has been assigned.
  #
  def empty?
    true
  end

  # Indicate whether data is valid and sufficient.
  #
  def complete?
    true
  end

  # Indicate whether operation(s) have failed.
  #
  def failures?
    failures.present?
  end

  # Indicate whether operation(s) have succeeded.
  #
  def succeeded?
    succeeded.present?
  end

  # Indicate whether submission is permissible.
  #
  def ready?
    succeeded? && !failures?
  end

end

# Support for methods used in the context of responding to workflow events.
#
module Workflow::Base::Actions
  include Workflow::Base::Data
end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

# Methods which are executed to initiate state transitions.
#
# The Workflow gem dynamically creates helper methods based on the *workflow*
# definition.  This module creates "shims" for each of these that insert
# additional logging support.
#
# @!method start!
# @!method start?
# @!method create!
# @!method create?
# @!method edit!
# @!method edit?
# @!method remove!
# @!method remove?
# @!method cancel!
# @!method cancel?
# @!method submit!
# @!method submit?
# @!method upload!
# @!method upload?
# @!method abort!
# @!method abort?
#
# @!method can_start?
# @!method can_create?
# @!method can_edit?
# @!method can_remove?
# @!method can_cancel?
# @!method can_submit?
# @!method can_upload?
# @!method can_abort?
#
# @!method advance!
# @!method advance?
# @!method fail!
# @!method fail?
# @!method suspend!
# @!method suspend?
# @!method schedule!
# @!method schedule?
# @!method approve!
# @!method approve?
# @!method reject!
# @!method reject?
# @!method hold!
# @!method hold?
# @!method assign!
# @!method assign?
# @!method review!
# @!method review?
# @!method index!
# @!method index?
# @!method timeout!
# @!method timeout?
# @!method resume!
# @!method resume?
# @!method purge!
# @!method purge?
# @!method reset!
# @!method reset?
#
# @!method can_advance?
# @!method can_fail?
# @!method can_suspend?
# @!method can_schedule?
# @!method can_approve?
# @!method can_reject?
# @!method can_hold?
# @!method can_assign?
# @!method can_review?
# @!method can_index?
# @!method can_timeout?
# @!method can_resume?
# @!method can_purge?
# @!method can_reset?
#
# @see Workflow::ClassMethods#assign_workflow
#
module Workflow::Base::Events

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All defined workflow events.
  #
  # @type [Array<Symbol>]
  #
  #--
  # noinspection LongLine
  #++
  EVENTS = [
    :start,    # Only used when debugging.

    # === Workflow events triggered by the user

    :create,   # The user initiates submission of a new entry.
    :edit,     # The user initiates modification of an existing entry.
    :remove,   # The user initiates removal of an existing entry.
    :cancel,   # The user chooses to cancel the submission process.
    :submit,   # The user chooses to proceed to the next step.
    :upload,   # The user supplies a file to upload. # TODO: new event
    :abort,    # The user chooses to terminate the workflow.

    # === Workflow events triggered by an entity other than the user

    :advance,  # The system moves to the next workflow step.
    :fail,     # The system has detected failure(s).
    :suspend,  # The system has suspended the workflow due to problems.
    :schedule, # The system has determined that the submission needs review.
    :approve,  # The system or reviewer indicates that the submission is acceptable.
    :reject,   # The system or reviewer indicates that the submission requires change(s).
    :hold,     # The system is waiting for a reviewer.
    :assign,   # The reviewer claims the submission for review or the system assigns a default reviewer.
    :review,   # The reviewer initiates review of the submission.
    :index,    # The system indicates the submission can be indexed directly.
    :timeout,  # The partner repository has not yet retrieved the submission.

    # === Workflow meta-events

    :resume,   # The system is returning to the previous workflow state.
    :purge,    # The system is removing all data associated with the submission.
    :reset,    # The system is resetting the workflow state.
  ].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # event_number
  #
  # @param [Symbol, String, nil]  event
  #
  # @return [Integer]             On error, -1 is returned.
  #
  def event_number(event)
    event && EVENTS.index(event.to_sym) || -1
  end

  # event_label
  #
  # @param [Symbol, String, nil]  event
  # @param [String, Boolean, nil] number
  #
  # @return [String]
  #
  def event_label(event, number: true)
    label  = '*%s*' % (event || 'MISSING')
    number = '%02d' if number.is_a?(TrueClass)
    number &&= number % event_number(event)
    number ? "[#{number}] #{label}" : label
  end

  # ===========================================================================
  # :section: Workflow overrides
  # ===========================================================================

  public

  # Override :workflow for a Workflow subclass in order to redefine the
  # workflow event methods.
  #
  # @param [any, nil] base            Workflow
  #
  # @see Workflow::ClassMethods#workflow
  #
  def self.included(base)
    return unless base.respond_to?(:workflow)
    # noinspection RbsMissingTypeSignature
    base.class_eval do

      def self.workflow(&specification)
        super(&specification)
        EVENTS.each do |event|

          # Override the method used to invoke the event to return *nil* if
          # there are failures.
          #
          define_method("#{event}!") do |*args|
            result = process_event!(event, *args)
            result unless failures?
          rescue => error
            self.failures << error unless failures?
            Log.warn { "#{event}!: #{error.class} #{error.message}" }
            re_raise_if_internal_exception(error)
          end

        end
      end

    end
  end

  # ===========================================================================
  # :section: Workflow debugging
  # ===========================================================================

  if DEBUG_WORKFLOW

    include Emma::Debug::OutputMethods

    include Workflow::Base::Roles

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # __debug_event
    #
    # @param [Symbol, String] event
    # @param [Array]          args
    #
    def __debug_event(event, *args)
      line = 'UPLOAD WF ***** EVENT ' + event_label(event)
      opt  = args.last.is_a?(Hash) ? args.pop.dup : {}
      __debug_line(line, *args, **opt, leader: "\n")
    end

    # =========================================================================
    # :section: Workflow overrides
    # =========================================================================

    public

    # Override :workflow for a Workflow subclass in order to redefine the
    # workflow event methods.
    #
    # @param [any, nil] base          Workflow
    #
    # @see Workflow::ClassMethods#workflow
    #
    def self.included(base)
      return unless base.respond_to?(:workflow)
      # noinspection RbsMissingTypeSignature
      base.class_eval do

        def self.workflow(&specification)
          super(&specification)
          EVENTS.each do |event|

            # Override the method used to invoke the event to provide
            # additional debugging information beyond what :process_event!
            # shows (but let it fail in order to raise an exception instead of
            # returning *nil*).
            #
            define_method("#{event}!") do |*args|
              if current_state.events.first_applicable(event, self).nil?
                c = self.class.name
                e = event.inspect
                r = wf_role.inspect
                u = wf_user.to_s.inspect
                s = curr_state.inspect
                m = "#{c} event #{e} not valid for #{u} (#{r}) in state #{s}"
                __debug_event(event, "ERROR: #{m}")
              end
              result = process_event!(event, *args)
              result unless failures?
            rescue => error
              self.failures << error unless failures?
              Log.warn { "#{event}!: #{error.class} #{error.message}" }
              re_raise_if_internal_exception(error)
            end

            # The method which is called when the event is triggered.
            #
            define_method(event) do |*args|
              __debug_event(event, *args)
            end

            protected event

          end
        end

      end
    end

  end

end

# Methods executed on transition into and out of a state.
#
# @!method on_starting_entry
# @!method on_starting_exit
#
# @!method on_creating_entry
# @!method on_creating_exit
# @!method on_validating_entry
# @!method on_validating_exit
# @!method on_submitting_entry
# @!method on_submitting_exit
# @!method on_submitted_entry
# @!method on_submitted_exit
#
# @!method on_editing_entry
# @!method on_editing_exit
# @!method on_replacing_entry
# @!method on_replacing_exit
# @!method on_modifying_entry
# @!method on_modifying_exit
# @!method on_modified_entry
# @!method on_modified_exit
#
# @!method on_removing_entry
# @!method on_removing_exit
# @!method on_removed_entry
# @!method on_removed_exit
#
# @!method on_scheduling_entry
# @!method on_scheduling_exit
# @!method on_assigning_entry
# @!method on_assigning_exit
# @!method on_holding_entry
# @!method on_holding_exit
# @!method on_assigned_entry
# @!method on_assigned_exit
# @!method on_reviewing_entry
# @!method on_reviewing_exit
# @!method on_rejected_entry
# @!method on_rejected_exit
# @!method on_approved_entry
# @!method on_approved_exit
#
# @!method on_staging_entry
# @!method on_staging_exit
# @!method on_unretrieved_entry
# @!method on_unretrieved_exit
# @!method on_retrieved_entry
# @!method on_retrieved_exit
#
# @!method on_indexing_entry
# @!method on_indexing_exit
# @!method on_indexed_entry
# @!method on_indexed_exit
#
# @!method on_suspended_entry
# @!method on_suspended_exit
# @!method on_failed_entry
# @!method on_failed_exit
# @!method on_canceled_entry
# @!method on_canceled_exit
# @!method on_completed_entry
# @!method on_completed_exit
#
# @!method on_purged_entry
# @!method on_purged_exit
#
# @see Workflow::InstanceMethods#run_on_entry
# @see Workflow::InstanceMethods#run_on_exit
#
module Workflow::Base::States

  include Workflow::Base::Events
  include Workflow::Base::Actions

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All defined workflow states.
  #
  # @type [Array<Symbol>]
  #
  #--
  # noinspection LongLine
  #++
  STATES = [
    :starting,    # Initial workflow state.

    # === "Create new entry" states

    :creating,    # The user is presented with the form for submitting a new item.
    :validating,  # The supplied file is being validated. # TODO: new state
    :submitting,  # The submission is complete and ready to move into the submission queue.
    :submitted,   # The submission is moving into the submission queue.

    # === "Modify existing entry" states

    :editing,     # The user is presented with the edit form pre-populated with previously-provided values.
    :replacing,   # The supplied replacement file is being validated. # TODO: new state
    :modifying,   # The modified submission is complete and ready to move into the submission queue.
    :modified,    # The modified submission is moving into the submission queue.

    # === "Remove existing entry" states

    :removing,    # The user is presented with a request for confirmation that the item should be submitted for removal.
    :removed,     # The removal request is created.

    # === "Sub-sequence: Review" states

    :scheduling,  # The submission is being scheduled for review.
    :assigning,   # The submission is being assigned for review.
    :holding,     # The system is waiting for a reviewer (or the review process is paused).
    :assigned,    # The submission has been assigned for review.
    :reviewing,   # The submission is under review.
    :rejected,    # The submission has been rejected.
    :approved,    # The submission has been approved.

    # === "Sub-sequence: Submission" states

    :staging,     # The submission request (submitted file plus generated request form) has been added to the staging area.
    :unretrieved, # The submission request has not been retrieved by the partner repository within a pre-determined maximum time span.
    :retrieved,   # The submission request has been retrieved by the partner repository and removed from the staging area.

    # === "Sub-sequence: Finalization" states

    :indexing,    # The submission is being added to the index.
    :indexed,     # The submission is complete and present in the EMMA Unified Index.

    # === Terminal states

    :suspended,   # The system is pausing the workflow; it may be resumable.
    :failed,      # The system is terminating the workflow.
    :canceled,    # The user is choosing to terminate the workflow.
    :completed,   # The workflow has been successfully completed.

    # === Pseudo states

    :resuming,    # Pseudo-state indicating the previous workflow state. # TODO: new
    :purged,      # All data associated with the submission is being eliminated. # TODO: new

  ].freeze

  # States that will not be assigned to @previous_state.
  #
  # @type [Array<Symbol>]
  #
  HIDDEN_STATE = %i[
    starting
    suspended
    failed
    canceled
    completed
    resuming
    purged
  ].freeze

  # ===========================================================================
  # :section: Workflow overrides
  # ===========================================================================

  protected

  STATES.each do |state|

    # Respond to entering into the specific state.
    #
    # @param [any]    _state
    # @param [Symbol] event
    # @param [Array]  event_args
    #
    # @return [self]                  For chaining.
    #
    define_method("on_#{state}_entry") do |_state, event, *event_args, **|
      __debug_entry(state, event, *event_args)
      self
    end

    # Respond to leaving the specific state.
    #
    # @param [any]    _state
    # @param [Symbol] event
    # @param [Array]  event_args
    #
    # @return [self]                  For chaining.
    #
    define_method("on_#{state}_exit") do |_state, event, *event_args, **|
      __debug_exit(state, event, *event_args)
      @prev_state = state unless HIDDEN_STATE.include?(state)
      self
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # state_object
  #
  # @param [Symbol, String, Workflow::State, nil] state
  #
  # @return [Workflow::State]
  #
  def state_object(state = nil)
    state = state.to_sym       if state.is_a?(String)
    state = spec.states[state] if state.is_a?(Symbol)
    # noinspection RubyMismatchedReturnType
    state || current_state
  end

  # state_number
  #
  # @param [Symbol, String, Workflow::State, nil] state
  #
  # @return [Integer]             On error, -1 is returned.
  #
  def state_number(state)
    STATES.index(state.to_sym) if state
  end

  # state_label
  #
  # @param [Symbol, String, Workflow::State, nil] state
  # @param [String, Boolean, nil]                 number
  #
  # @return [String]
  #
  def state_label(state, number: true)
    label  = state&.to_s || 'MISSING'
    number = '%02d' if number.is_a?(TrueClass)
    number &&= number % state_number(state)
    number ? "#{label}(#{number})" : label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  include Emma::Debug::OutputMethods if DEBUG_WORKFLOW

  # __debug_entry
  #
  # @param [any, nil] state           State that is being entered.
  # @param [Symbol]   _event          Triggering event
  # @param [Array]    _event_args
  #
  def __debug_entry(state, _event = nil, *_event_args, **)
    state = state_object(state)
    trans =
      state.events.map { |evt, entry|
        event_label(evt, number: false) << '->' <<
          entry.map { |e|
            state_label(e.transitions_to, number: false)
          }.join(',')
      }.join('; ')
    state = state_label(state)
    __debug_wf(">>>>> ENTER #{state} => [#{trans}]")
  end
    .tap { |meth| neutralize(meth) unless DEBUG_WORKFLOW }

  # __debug_exit
  #
  # @param [any, nil] state           State that is being exited.
  # @param [Symbol]   _event          Triggering event
  # @param [Array]    _event_args
  #
  def __debug_exit(state, _event = nil, *_event_args, **)
    state = state_label(state)
    __debug_wf("<<<<< LEAVE #{state}")
  end
    .tap { |meth| neutralize(meth) unless DEBUG_WORKFLOW }

  # __debug_wf
  #
  # @param [Array<*>] args            Passed to #__debug_line.
  # @param [Hash]     opt
  # @param [Proc]     blk             Passed to #__debug_line.
  #
  def __debug_wf(*args, **opt, &blk)
    __debug_line(*args, leader: 'UPLOAD WF', **opt, &blk)
  end
    .tap { |meth| neutralize(meth) unless DEBUG_WORKFLOW }

end

# Hooks executed during transitions.
#
# === Usage Notes
# These are generally only of interest for detailed debugging because logic
# associated with specific transitions is applied by defining the appropriate
# "on_*_entry" method in WorkflowStates.
#
module Workflow::Base::Transitions
end

# =============================================================================
# :section: Base for workflow classes
# =============================================================================

public

# Common workflow aspects.
#
# @!attribute prev_state
#   @return [Symbol, nil]
#
class Workflow::Base

  include Workflow::Base::Roles
  include Workflow::Base::Events
  include Workflow::Base::States
  include Workflow::Base::Transitions

  # ===========================================================================
  # :section: Workflow event definition options
  # ===========================================================================

  public

  IF_DEBUG    = { if: ->(*)  { DEBUG_WORKFLOW } }.freeze
  IF_COMPLETE = { if: ->(wf) { wf.user_wf? && wf.complete? } }.freeze
  IF_READY    = { if: ->(wf) { wf.user_wf? && wf.ready? } }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Last state before :suspended, :failed, :canceled, or :completed.
  #
  # @return [Symbol, nil]
  #
  attr_reader :prev_state

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [any, nil] data
  # @param [Hash]     opt             Passed to #initialize_state
  #
  # @option opt [User, String] :user
  #
  def initialize(data, **opt)
    @params        = opt[:params]  || {}
    @model_options = opt[:options] || Upload::Options.new(@params)
    set_wf_user(opt[:user])
    initialize_state(data, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Set initial state.
  #
  # @param [any, nil] data
  # @param [Hash]     opt
  #
  # @option opt [Symbol, String] :start_state
  # @option opt [Symbol, String] :init_event
  #
  # @return [void]
  #
  def initialize_state(data, **opt)
    __debug(separator: ' | ') do
      ["UPLOAD WF #{__method__}"] <<
        "curr_state = #{curr_state.inspect}" <<
        "init_state = #{init_state.inspect}" <<
        "opt[:start_state] = #{opt[:start_state].inspect}" <<
        "opt[:init_event] = #{opt[:init_event].inspect}"
    end
    state = opt[:start_state].presence&.to_sym
    state = nil if state == init_state
    event = opt[:init_event].presence&.to_sym

    reset_status

    # Set initial state if specified.
    if state
      __debug { "UPLOAD WF initial state: #{state.inspect}" }
      persist_workflow_state(state)
    end

    # Apply initial event if specified.
    if event
      __debug { "UPLOAD WF initial event: #{event.inspect}" }
      event = "#{event}!" unless event.end_with?('!')
      send(event, *Array.wrap(data.presence))
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current workflow state name.
  #
  # @return [Symbol]
  #
  def curr_state
    current_state.to_sym
  end

  # Initial workflow state name.
  #
  # @return [Symbol]
  #
  def init_state
    spec.initial_state.to_sym
  end

  # Final (completed) workflow state name.
  #
  # @return [Symbol]
  #
  def final_state
    self.class.final_state
  end

  # ===========================================================================
  # :section: Workflow overrides
  # ===========================================================================

  protected

  # Get the current state of the workflow item.
  #
  # @return [String]
  #
  def load_workflow_state
    super.to_s
  end

  # Set the current state of the workflow item.
  #
  # @param [Symbol, String] new_value
  #
  # @return [String]
  #
  def persist_workflow_state(new_value)
    super(new_value.to_s)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The table field associated with workflow state.
  #
  # @return [Symbol]
  #
  def workflow_column
    self.class.workflow_column
  end

  # Return the workflow type.
  #
  # @return [Symbol]
  #
  def workflow_type
    self.class.workflow_type
  end

  # The workflow phase is indicated by the variant type of the subclass.
  #
  # @return [Symbol, nil]
  #
  def workflow_phase
    self.class.workflow_phase
  end

  # Return the variant workflow type or *nil* if the class is not a workflow
  # variant subclass.
  #
  # @return [Symbol, nil]
  #
  def variant_type
    self.class.variant_type
  end

  # ===========================================================================
  # :section:  Workflow overrides
  # ===========================================================================

  public

  # The table field associated with workflow state.
  #
  # @param [any, nil] column_name     Ignored.
  #
  # @return [Symbol]
  #
  def self.workflow_column(column_name = nil)
    must_be_overridden
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Workflow model configuration.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def self.configuration
    CONFIGURATION[workflow_type] || {}
  end

  # Workflow state labels.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def self.state_label
    (configuration[:state] || {}).map { |state, properties|
      next if properties.blank?
      next if true?(properties[:disabled]) || false?(properties[:enabled])
      state_label = properties[:label] || state.to_s.upcase
      [state, state_label]
    }.compact.to_h
  end

  # Final (completed) workflow state name.
  #
  # @return [Symbol]
  #
  def self.final_state
    FINAL_STATE
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Return the workflow type which is a key under "en.emma.workflow".
  #
  # @return [Symbol]
  #
  def self.workflow_type
  end

  # The workflow phase is indicated by the variant type of the subclass.
  #
  # @return [Symbol, nil]
  #
  def self.workflow_phase
    variant_type
  end

  # Return the variant workflow type or *nil* if the class is not a workflow
  # variant subclass.
  #
  # @return [Symbol, nil]
  #
  def self.variant_type
  end

  # The default workflow variant type.
  #
  # @return [Symbol, nil]
  #
  def self.default_variant
    :create
  end

  # Table of variant workflow types under this workflow base class.
  #
  # @return [Hash{Symbol=>Class<UploadWorkflow>}]
  #
  def self.variant_table
    must_be_overridden
  end

  # Variant workflow types under this workflow base class.
  #
  # @return [Array<Symbol>]
  #
  def self.variant_types
    variant_table.keys
  end

  # Indicate whether the value denotes a workflow variant.
  #
  # @param [Symbol, String, nil] value
  #
  def self.variant?(value)
    variant_types.include?(value.to_sym) if value.present?
  end

  # Generate a new instance of the appropriate workflow variant subclass
  # (or the workflow base class if the variant could not be found).
  #
  # @param [any, nil] data
  # @param [Hash]     opt             Passed to #initialize_state except for:
  #
  # @option opt [Symbol,String] :variant
  #
  # @return [Workflow::Base]
  #
  def self.generate(data, **opt)
    variant  = (opt.delete(:variant) || opt[:event])&.to_sym
    subclass = variant_table[variant] || variant_table[default_variant] || self
    subclass.new(data, **opt)
  end

end

__loading_end(__FILE__)
