# app/models/phase/review.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Review workflow tracking record.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.phase.review*
#
# @!method started?
# @!method scheduling?
# @!method assigned?
# @!method reviewing?
# @!method rejected?
# @!method approved?
# @!method canceling?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method scheduling!
# @!method assigned!
# @!method reviewing!
# @!method rejected!
# @!method approved!
# @!method canceling!
# @!method canceled!
# @!method aborted!
#
class Phase::Review < Phase::Single

  include Record::Sti::Leaf
  include Record::Steppable

  # @private
  CLASS = self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # schedule!
  #
  # @param [Hash] opt
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def schedule!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:scheduling, **opt) or return
    set_callback!(opt, :schedule_cb)

    # TODO: schedule review

    false
  end

  # Method called from the action launched by #schedule!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def schedule_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # review!
  #
  # @param [Hash] opt
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def review!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:reviewing, **opt) or return
    set_callback!(opt, :review_cb)

    # TODO: perform review

    false
  end

  # Method called from the action launched by #review!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def review_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # cancel!
  #
  # @param [Hash] opt
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def cancel!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:canceling, **opt) or return
    set_callback!(opt, :cancel_cb)

    # TODO: cancel review

    false
  end

  # Method called from the action launched by #cancel!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def cancel_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Reviewer rejects (sends back) submission.
  #
  # @param [String, nil] comments     Passed to #terminate_phase!
  # @param [Hash]        opt          Passed to #terminate_phase!
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def reject!(comments = nil, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    set_callback!(opt, :reject_cb)
    terminate_phase!(:rejected, comments, **opt)
  end

  # Method called from the action launched by #reject!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def reject_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Reviewer approves (sends forward) submission.
  #
  # @param [String, nil] comments     Passed to #terminate_phase!
  # @param [Hash]        opt          Passed to #terminate_phase!
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def approve!(comments = nil, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    set_callback!(opt, :approve_cb)
    terminate_phase!(:approved, comments, **opt)
  end

  # Method called from the action launched by #approve!.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [Boolean]   *false* if the callback's callback failed to process.
  #
  def approve_cb(action = nil, **opt)
    action = opt.delete(:from) || action
    __debug { "CALLBACK #{CLASS}.#{__method__} | #{action.inspect} | #{opt.inspect}" } # TODO: remove
    raise 'NO ACTION' if action.blank? # TODO: remove
    if action.failed?
      aborted!
      false
    else
      run_callback(**opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Complete the review phase.
  #
  # @param [Symbol, String] final_state
  # @param [String, nil]    comments
  # @param [Hash]           opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [nil]       Failed to transition record to the new state.
  # @return [Boolean]   *false* if the action could not be processed.
  #
  def terminate_phase!(final_state, comments = nil, **opt)
    unless final_state?(final_state)
      Log.warn { "#{opt[:meth]}: #{final_state}: not a final state" }
    end
    update!(state: final_state, remarks: comments&.strip).tap do

      # TODO: what drives the next workflow step?

    end
    false # TODO: ???
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @return [String]
  #
  def self.describe_type(*)
    'is being submitted for review' # TODO: I18n
  end

  # A textual description of the status of the given Phase instance. # TODO: I18n
  #
  # @param [Phase] phase
  # @param [Hash]  opt
  #
  # @option opt [Symbol] :state       Override #state_value.
  #
  # @return [String]
  #
  def self.describe_status(phase, **opt)
    state = opt[:state]
    unless opt.key?(:state)
      action = opt[:action] || phase.current_action
      state  = action&.state_value || phase.state_value
    end
    # noinspection RubyCaseWithoutElseBlockInspection
    case state
      when :reviewing then 'is now being reviewed'
      when :rejected  then 'was reviewed and rejected'
      when :rejected  then 'was reviewed and approved'
      when :assigned  then 'has been submitted for review'
      when :canceled  then 'canceled after being submitted for review'
    end || [describe_type(phase, **opt), state].compact.join(' - ')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  validate_state_table unless application_deployed?

end

__loading_end(__FILE__)
