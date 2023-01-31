# app/models/action/un_index.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage removal of an entry from the Unified Index.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.un_index*
#
# @!method started?
# @!method deindexing?
# @!method completed?
# @!method canceled?
# @!method aborted?
#
# @!method started!
# @!method deindexing!
# @!method completed!
# @!method canceled!
# @!method aborted!
#
class Action::UnIndex < Action::BulkPart

  include Record::Sti::Leaf
  include Record::Steppable
  include Record::Uploadable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remove the index entry.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def deindex!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_sequence(**opt) {{
      deindexing: ->(*) { ingest_action(:delete_records) },
      completed:  true
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
    'removing from index' # TODO: I18n
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

  validate_state_table if sanity_check?

end

__loading_end(__FILE__)
