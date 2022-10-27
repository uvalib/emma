# app/models/action/batch_un_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Remove item records from the database.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.batch_un_record*
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
class Action::BatchUnRecord < Action::BulkOperation

  include Record::Sti::Leaf
  include Record::Steppable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remove the item from the database.
  #
  # @param [Array] items
  # @param [Hash]  opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def remove!(items, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    prev_state = transition_to(:removing, **opt) or return false

    __output "!!!!!!!!!!!!! TODO: #{self.class} #{__method__} !!!!!!!!!!!!"
    success = nil # TODO: partition items into batches, run each batch as a job...

    run_callback(**opt) if success
    success.present?
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
    'removing from database: %{targets}' # TODO: I18n
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
