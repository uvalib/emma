# app/models/action/batch_index.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Add or update entries in the Unified Index.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.batch_index*
#
# @!method started?
# @!method indexing?
# @!method indexed?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method indexing!
# @!method indexed!
# @!method canceled!
# @!method aborted!
#
class Action::BatchIndex < Action::BulkOperation

  include Record::Sti::Leaf
  include Record::Steppable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Add items to the Unified Index.
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
  def index!(items, **opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    prev_state = transition_to(:indexing, **opt) or return false

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
    'indexing %{targets}' # TODO: I18n
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

  validate_state_table if sanity_check?

end

__loading_end(__FILE__)
