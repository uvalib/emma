# app/models/phase.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A 'phases' table record which tracks a workflow involving an Entry.
#
# @!attribute [r]  entry_id
#   The EMMA entry associated with this workflow instance.
#
# @!attribute [r]  user_id
#   The user who initiated this workflow instance.
#
# @!attribute [rw] command
#   Control command to be honored by the workflow process using this instance.
#
# @!attribute [r]  type
#   Phase STI subclass.
#
# @!attribute [rw] state
#   Phase::*.state_values
#
# @!attribute [rw] remarks
#   Reviewer comments.
#   (Phase::Review only)
#
# @!attribute [rw] submission_id
#   The EMMA entry associated with this workflow instance.
#   (Phase::Create or Phase::Edit only - when :emma_data is updated)
#   TODO: probably don't need to break this out
#
# @!attribute [rw] repository
#   The repository for the EMMA entry associated with this workflow instance.
#   (Phase::Create or Phase::Edit only - when :emma_data is updated)
#   TODO: probably don't need to break this out
#
# @!attribute [rw] fmt
#   The format of the file uploaded for this workflow instance.
#   (Phase::Create or Phase::Edit only - when :file_data is updated)
#   TODO: probably don't need to break this out
#
# @!attribute [rw] ext
#   The extension of the file uploaded for this workflow instance.
#   (Phase::Create or Phase::Edit only - when :file_data is updated)
#   TODO: probably don't need to break this out
#
# @!attribute [rw] emma_data
#   JSON metadata extracted from the file uploaded for this workflow instance.
#   (Phase::Create or Phase::Edit only)
#
# @!attribute [rw] file_data
#   Shrine metadata for the file uploaded for this workflow instance.
#   (Phase::Create or Phase::Edit only)
#
# @!attribute [r]  created_at
#   Time of record creation.
#
# @!attribute [rw] updated_at
#   Last time record was modified.
#
class Phase < ApplicationRecord

  DESTRUCTIVE_TESTING = false

  include Model

  include Record
  include Record::Sti::Root
  include Record::Bulk::Root
  include Record::EmmaData
  include Record::Assignable
  include Record::Authorizable
  include Record::Controllable
  include Record::Describable
  include Record::Reportable
  include Record::Searchable
  include Record::Submittable
  include Record::Updatable

  include Record::Testing
  include Record::Debugging

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Controllable::CommandMethods
    extend  Record::Describable::ClassMethods
    # :nocov:
  end

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  belongs_to :user,  optional: true
  belongs_to :entry, optional: true

  has_many :actions #, dependent: :destroy # TODO: destroying a Phase should destroy its Actions

  # ===========================================================================
  # :section: ActiveRecord scopes # TODO: keep?
  # ===========================================================================

  scope :creates,       ->(**opt) { where(type: :Create,     **opt) }
  scope :edits,         ->(**opt) { where(type: :Edit,       **opt) }
  scope :removes,       ->(**opt) { where(type: :Remove,     **opt) }
  scope :reviews,       ->(**opt) { where(type: :Review,     **opt) }
  scope :bulk_creates,  ->(**opt) { where(type: :BulkCreate, **opt) }
  scope :bulk_edits,    ->(**opt) { where(type: :BulkEdit,   **opt) }
  scope :bulk_removes,  ->(**opt) { where(type: :BulkRemove, **opt) }

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Update database fields, including the structured contents of the :emma_data
  # field.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attributes
  #
  # @return [void]
  #
  # @see Record::EmmaData#EMMA_DATA_KEYS
  #
  def assign_attributes(attributes)
    __debug_items(binding)
    attr = normalize_attributes(attributes)
    opt  = attr.delete(:attr_opt) || {}
    data = extract_hash!(attr, *EMMA_DATA_KEYS)
    attr[:emma_data] = generate_emma_data(data, attr)
    super(attr.merge!(opt))
  end

  # ===========================================================================
  # :section: Record::ConditionMethods delegations
  # ===========================================================================

  public

  def running?
    newest_action&.condition == :running
  end

  def paused?
    newest_action&.condition == :paused
  end

  def waiting?
    newest_action&.condition == :waiting
  end

  def resuming?
    newest_action&.condition == :resuming
  end

  def retrying?
    newest_action&.condition == :retrying
  end

  def restarting?
    newest_action&.condition == :restarting
  end

  def failed?
    newest_action&.condition == :failed
  end

  def succeeded?
    newest_action&.condition == :succeeded
  end

  # ===========================================================================
  # :section: Record::Reportable overrides
  # ===========================================================================

  public

  # Fetch the error report from the latest action.
  #
  # @param [Boolean, nil] refresh     If *false*, don't re-fetch.
  #
  # @return [ExecReport, nil]
  #
  def get_exec_report(refresh = true)
    failed_action&.exec_report(refresh)
  end

  # Phase records don't have a REPORT_COLUMN.
  #
  # @raise [RuntimeError]
  #
  def set_exec_report(...)
    not_implemented "invalid for #{self.class}"
  end

  # Phase records don't have a REPORT_COLUMN.
  #
  # @raise [RuntimeError]
  #
  def clear_exec_report(...)
    not_implemented "invalid for #{self.class}"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The most-recently created action.
  #
  # @return [Action, nil]
  #
  def newest_action
    # noinspection RubyMismatchedReturnType
    actions.order(:created_at).last
  end

  # The most-recently updated action, representing the current status of the
  # Phase instance.
  #
  # @return [Action, nil]
  #
  def current_action
    # noinspection RubyMismatchedReturnType
    actions.order(:updated_at).last
  end

  # The latest failed action.
  #
  # @return [Action, nil]
  #
  def failed_action
    # noinspection RubyMismatchedReturnType
    actions.where(condition: :failed).order(:created_at).last
  end

  # Actions that are not finished.
  #
  # @return [Array<Action>]
  #
  # @note Currently unused
  #
  def active_actions
    actions.not(final_condition).order(updated_at: :desc).to_a
  end

  # Get Action records associated with this record for the action given either
  # as *action_type* or `opt[:type]`.
  #
  # @param [Symbol,String,Action,Class,nil] action_type   Def: #current_action.
  # @param [Hash]                           opt           For #where.
  #
  # @return [ActiveRecord::Relation<Action>]
  #
  # @note Currently unused
  #
  def action_scope(action_type = nil, **opt)
    opt[:type] = Action.type(action_type || opt[:type] || current_action)
    # noinspection RubyMismatchedReturnType
    actions.where(**opt)
  end

  # Create a new Action for this Phase, initializing it with the current values
  # from this record.
  #
  # @param [Symbol, String, nil] type     If *nil*, opt[:type] must be present.
  # @param [Hash]                opt      Passed to ActiveRecord#create
  #
  # @raise [Record::SubmitError]            If type not given.
  # @raise [ActiveRecord::RecordInvalid]    Update failed due to validations.
  # @raise [ActiveRecord::RecordNotSaved]   Update halted due to callbacks.
  #
  # @return [Action]
  #
  def generate_action(type, **opt)
    type ||= opt[:type] or failure("#{__method__}: no type given")
    opt[:type]  = Action.type(type)
    opt[:state] = :started
    opt[:from]  = self
    actions.create!(**opt)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Error messages for various states.
  #
  # TODO: Move into STATE_TABLE?
  #
  # @type [Hash{Symbol=>String}]
  #
  STATE_MESSAGE = {
    uploading: 'No uploaded file for %{submission} (Phase ID %{id})',
    indexed:   '%{Submission} failed'
  }.freeze

  # Raise an exception if *phase* is not in the indicated state.
  #
  # @param [Phase]               phase
  # @param [Symbol, String, nil] state
  #
  # @raise [Record::SubmitError]
  #
  # @return [Phase]
  #
  def self.raise_unless(phase, state)
    return phase if phase.state_value.presence == (state = state&.to_sym)
    problem = STATE_MESSAGE[state]
    problem &&= interpolations(problem, phase)
    problem ||= "#{__method__}: #{state.inspect} unexpected" # TODO: I18n
    failure(problem)
  end

  # ===========================================================================
  # :section: Record::Reportable overrides
  # ===========================================================================

  public

  # Delegate to the reporting methods of the latest failed action.
  Record::Reportable.tap do |mod|
    mod.instance_methods(false).each do |meth|
      if mod.instance_method(meth).arity.zero?
        define_method(meth) { failed_action.try(meth) }
      else
        define_method(meth) { |*args| failed_action.try(meth, *args) }
      end
    end
  end

  # ===========================================================================
  # :section: Record::Searchable::ClassMethods overrides
  # ===========================================================================

  public

  # Get the latest matching Phase record.
  #
  # @param [Model, Hash, String, Symbol, nil] sid
  # @param [Hash]                             opt
  #
  # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
  # @raise [Record::NotFound]           If record not found.
  #
  # @return [Phase]
  #
  def self.latest_for_sid(sid = nil, **opt)
    opt[:sort] = :updated_at unless opt.key?(:sort)
    opt[:type] = type        unless opt.key?(:type) || sti_base?
    # noinspection RubyMismatchedReturnType
    super(sid, **opt)
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @param [Phase] phase
  # @param [Hash]  opt
  #
  # @return [String]
  #
  def self.describe_type(phase, **opt)
    type = opt[:type] || phase.type_value
    type ? "in phase #{type.inspect}" : 'in an unknown phase' # TODO: I18n
  end

  # A textual description of the status of the Phase instance.
  #
  # @param [Phase] phase
  # @param [Hash]  opt                To Action#describe_status except for:
  #
  # @option opt [String] :note
  # @option opt [Action] :action
  #
  # @return [String]
  #
  def self.describe_status(phase, **opt)
    action = opt.delete(:action) || phase.current_action
    note   = opt.delete(:note)   || describe_type(phase, **opt)
    note   = interpolations(note, phase, **opt)
    status = action&.describe_status(**opt) || phase.state_value
    [note.presence, (status.presence && "[#{status}]")].compact.join(' ')
  end

  # ===========================================================================
  # :section: Record::Describable
  # ===========================================================================

  interpolation_methods do

    def describe_parts(phase = nil, **opt)
      unless (group = opt[:bulk_id])
        phase ||= self_for_instance_method(__method__)
        case phase
          when Phase::BulkPart      then group = phase.bulk.id
          when Phase::BulkOperation then group = phase.id
        end
      end
      return if group.blank?
      count = Phase.where(bulk_id: group).count
      parts = 'part'.pluralize(count) # TODO: I18n
      "#{count} #{parts}"
    end

  end

  # ===========================================================================
  # :section: Record::Debugging overrides
  # ===========================================================================

  public

  if DEBUG_RECORD

    def show
      super(:user, :entry, :actions, :current_action)
    end

    def self.show
      scopes = %i[Create Edit Remove Review]
      super(*scopes.map { |t| "where(type: :#{t})" })
    end

  end

end

# =============================================================================
# Pre-load Phase subclasses for easier TRACE_LOADING.
# =============================================================================

require_subclasses(__FILE__)

__loading_end(__FILE__)
