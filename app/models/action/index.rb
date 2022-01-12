# app/models/action/index.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage creation of an entry in the Unified Index.
#
# @see file:config/locales/state_table.en.yml *en.emma.state_table.action.index*
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
class Action::Index < Action::BulkPart

  include Record::Sti::Leaf
  include Record::Steppable
  include Record::Uploadable

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Update database fields, including the structured contents of the :emma_data
  # field.
  #
  # @param [Hash, ActionController::Parameters, Model, nil] attr
  # @param [Hash, nil]                                      opt
  #
  # @return [void]
  #
  # @see Record::EmmaData#EMMA_DATA_KEYS
  #
  def assign_attributes(attr, opt = nil)
    __debug_items(binding)
    data, attr = partition_hash(attr, *EMMA_DATA_KEYS)
    attr = attribute_options(attr, opt)
    attr[:emma_data] = generate_emma_data(data, attr)
    super(attr, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create/upload the index entry.
  #
  # @param [Hash] opt
  #
  # @option opt [Boolean] :async      If *true* run callback asynchronously.
  # @option opt [Symbol]  :meth       Name of caller (for logging).
  #
  # @return [Boolean]
  #
  def index!(**opt)
    __debug_step(binding)
    opt[:meth] ||= __method__
    transition_sequence(**opt) {{
      indexing: ->(*, **) { ingest_action(:put_records) },
      indexed:  true
    }} and run_callback(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item is in the index.
  #
  # @param [String, nil] sid          Default: `#sid_value`
  # @param [Hash]        opt
  #
  def in_index?(sid = nil, **opt)
    sid = sid_value(sid || opt.presence)
    ingest_api.get_records(sid).present?
  end

  # For a (member repository) submission in the :indexing state, check to
  # determine whether the index has finally received the associated update from
  # the member repository.  If so then advance the workflow state.
  #
  # @param [String, nil] sid          Default: `#sid_value`
  # @param [Boolean]     advance      If *false* do not advance workflow state.
  #
  # @return [String]
  #
  def check_indexed(sid = nil, advance: true, **opt)                            # NOTE: from UploadWorkflow::Single::Actions#wf_check_indexed
    sid  = sid_value(sid || opt.presence)
    repo = repository_value(opt.presence)
    sub  = "submission #{sid.inspect}" # TODO: I18n
    sub  = "#{repository_name(repo)} #{sub}" unless emma_native?(repo)
    done = in_index?(sid)
    indexed! if done && !false?(advance)
    if done
      "the index service is now processing #{sub}" # TODO: I18n
    else
      "#{sub} has not yet been included in the index" # TODO: I18n
    end
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
    'indexing' # TODO: I18n
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
