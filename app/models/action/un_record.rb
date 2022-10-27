# app/models/action/un_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Remove item from the database.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.un_record*
#
# @!method started?
# @!method removing?
# @!method completed?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method removing!
# @!method completed!
# @!method canceled!
# @!method aborted!
#
class Action::UnRecord < Action::BulkPart

  include Record::Sti::Leaf
  include Record::Steppable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remove the item from the database.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def remove!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_sequence(**opt) {{
      removing:  ->(*, **) {
        __output "!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!" # TODO: remove record
      },
      completed: true
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
    'removing from database' # TODO: I18n
  end

  # A textual description of the status of the Action instance.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @return [String]
  #
  def self.describe_status(action, **opt)
    opt[:note] ||= describe_type(action, **opt)
    super(action, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  validate_state_table unless application_deployed?

end

__loading_end(__FILE__)
