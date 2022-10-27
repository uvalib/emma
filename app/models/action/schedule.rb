# app/models/action/schedule.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Control record scheduling a reviewer.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.schedule*
#
# NOTE: from "Review sub-sequence"
#
# @!method started?
# @!method scheduling?
# @!method assigning?
# @!method holding?
# @!method assigned?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method scheduling!
# @!method assigning!
# @!method holding!
# @!method assigned!
# @!method canceled!
# @!method aborted!
#
class Action::Schedule < Action::Single

  include Record::Sti::Leaf
  include Record::Steppable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Schedule a review.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def schedule!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_sequence(**opt) {{
      scheduling: ->(*, **) {
        __output "!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!" # TODO: schedule review
      },
      assigning:  ->(*, **) { assign! }
    }} and run_callback(**opt)
  end

  # Assign a reviewer.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def assign!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_sequence(**opt) {{
      assigning: ->(*, **) {
        __output "!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!" # TODO: assign reviewer
      },
      holding:   true
    }} and run_callback(**opt)
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @return [String]
  #
  def self.describe_type(...)
    'submitting for review' # TODO: I18n
  end

  # A textual description of the status of the Action instance.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [String]
  #
  def self.describe_status(action, **opt)
    opt[:note]   = action.state_note
    opt[:state]  = (action.state_description unless opt[:note])
    opt[:note] ||= describe_type(action, **opt)
    super(action, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  validate_state_table unless application_deployed?

end

__loading_end(__FILE__)
