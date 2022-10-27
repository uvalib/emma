# app/models/action/review.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Control record for an on-going review.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.review*
#
# NOTE: from "Review sub-sequence"
#
# @!method started?
# @!method reviewing?
# @!method holding?
# @!method approved?
# @!method rejected?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method reviewing!
# @!method holding!
# @!method approved!
# @!method rejected!
# @!method canceled!
# @!method aborted!
#
class Action::Review < Action::Single

  include Record::Sti::Leaf
  include Record::Steppable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Mark the start of a review.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def review!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:reviewing, **opt) or return false
    __output "!!!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!!!" # TODO: review start
    run_callback(**opt)
  end

  # Note that a started review was put on hold.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def hold!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:holding, **opt) or return false
    __output "!!!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!!!" # TODO: review hold
    run_callback(**opt)
  end

  # Note the positive outcome of a review.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def approve!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:approved, **opt) or return false
    __output "!!!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!!!" # TODO: review approve
    run_callback(**opt)
  end

  # Note the negative outcome of a review.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def reject!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:rejected, **opt) or return false
    __output "!!!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!!!" # TODO: review reject
    run_callback(**opt)
  end

  # Note the cancellation of a review.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def cancel!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_to(:canceled, **opt) or return false
    __output "!!!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!!!" # TODO: review cancel
    run_callback(**opt)
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
    'reviewing' # TODO: I18n
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
