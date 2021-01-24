# app/models/upload/workflow_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Workflow support for Upload records.
#
module Upload::WorkflowMethods

  include Emma::Debug

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEFAULT_REVIEW_REQUIRED = false
  DEFAULT_AUTO_REVIEWABLE = false

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The table column associated generally associated with workflow state.
  #
  # @type [Symbol]
  #
  WORKFLOW_PHASE_COLUMN = :phase

  # The table columns associated with workflow state in general and workflow
  # state in the context of modifying an existing EMMA entry.
  #
  # @type [Array<Symbol>]
  #
  STATE_COLUMNS = [
    PRIMARY_STATE_COLUMN   = :state,
    SECONDARY_STATE_COLUMN = :edit_state
  ].freeze

  # The table columns associated with the active workflow user.
  #
  # @type [Array<Symbol>]
  #
  USER_COLUMNS = %i[user_id edit_user review_user].freeze

  # Groupings of states related by theme.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/controllers/upload.en.yml
  #
  #--
  # noinspection RailsI18nInspection
  #++
  STATE_GROUP =
    I18n.t('emma.upload.state_group', default: {}).transform_values { |entry|
      states = Array.wrap(entry[:states]).map(&:to_sym)
      entry.merge(states: states)
    }.deep_freeze

  # Mapping of workflow state to category.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  REVERSE_STATE_GROUP =
    STATE_GROUP.flat_map { |group, entry|
      entry[:states].map { |state| [state,  group] }
    }.sort.to_h.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database column currently associated with the workflow state of the
  # record.
  #
  # @return [Symbol]
  #
  def state_column
    edit_phase ? SECONDARY_STATE_COLUMN : PRIMARY_STATE_COLUMN
  end

  # The database column currently associated with the active user.
  #
  # @return [Symbol]
  #
  def user_column
    if under_review?
      :review_user
    elsif edit_phase
      :edit_user
    else
      :user_id
    end
  end

  # The database column currently associated with the timestamp of the record.
  #
  # @return [Symbol]
  #
  def timestamp_column
    if under_review?
      :reviewed_at
    elsif edit_phase
      :edited_at
    else
      :updated_at
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database column currently associated with the workflow phase of the
  # record.
  #
  # @return [Symbol]
  #
  def phase_column
    WORKFLOW_PHASE_COLUMN
  end

  # Current workflow phase of the record.
  #
  # @return [Symbol, nil]
  #
  def workflow_phase
    self[phase_column]&.to_sym
  end

  # Indicate whether this record is currently being used in an Edit workflow.
  #
  # @return [Boolean]
  #
  def edit_phase
    workflow_phase == :edit
  end

  # The current workflow state of the record.
  #
  # @return [Symbol, nil]
  #
  def active_state
    self[state_column]&.to_sym
  end

  # The user currently associated with the record's workflow.
  #
  # @return [String, nil]
  #
  def active_user
    User.find_uid(self[user_column])
  end

  # Indicate whether this record represents an existing EMMA entry.
  #
  # @return [Boolean]
  #
  def existing_entry?
    p = workflow_phase
    p.present? && (p != :create) || (active_state == :completed)
  end

  # Indicate whether this record represents a new EMMA entry.
  #
  # @return [Boolean]
  #
  def new_submission?
    !existing_entry?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the current real-time value of the record's workflow phase.
  #
  # @return [Symbol]  If the field was *nil* it will come back as :''.
  #
  def get_phase
    dynamic_get_field(phase_column).to_s.to_sym
  end

  # Set the current real-time value of the record's workflow phase.
  #
  # @param [Symbol, String, nil] new_value
  #
  # @return [Symbol]  If the field was *nil* it will come back as :''.
  #
  # == Usage Notes
  # Entering #edit_state also requires execution of #begin_editing in order
  # to set up the record.
  #
  def set_phase(new_value)
    old_phase = phase.to_s
    new_phase = new_value.to_s
    Log.debug do
      "Upload##{__method__}: #{old_phase.inspect} -> #{new_phase.inspect}"
    end
    unless new_phase == old_phase
      dynamic_set_field(new_phase.presence, phase_column)
    end
    new_phase.to_sym
  end

  # Get the current real-time value of the indicated workflow state field.
  #
  # @param [Symbol, String, nil] column     Default: `#PRIMARY_STATE_COLUMN`
  #
  # @return [Symbol]  If the field was *nil* it will come back as :''.
  #
  def get_state(column = nil)
    dynamic_get_field(column || PRIMARY_STATE_COLUMN).to_s.to_sym
  end

  # Set the current real-time value of the indicated workflow state field.
  #
  # @param [Symbol, String, nil] new_value
  # @param [Symbol, String, nil] column     Default: `#PRIMARY_STATE_COLUMN`
  #
  # @return [Symbol]  If the field was *nil* it will come back as :''.
  #
  # == Usage Notes
  # Leaving #edit_state also requires execution of #finish_editing in order
  # to update the record with information that may have changed.
  #
  def set_state(new_value, column = nil)
    column    = column&.to_sym || PRIMARY_STATE_COLUMN
    old_state = self[column].to_s
    new_state = new_value.to_s
    Log.debug do
      "Upload##{__method__}: #{phase} phase:" \
      "#{old_state.inspect} -> #{new_state.inspect}"
    end
    unless new_state == old_state
      # noinspection RubyYardParamTypeMatch
      dynamic_set_field(new_state.presence, column)
    end
    new_state.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the current real-time value of a database field.
  #
  # @param [Symbol, String] column    Database field name.
  #
  # @return [*, nil]
  #
  def dynamic_get_field(column)
    if new_record?
      self[column]
    else
      read_attribute(column)
    end
  end

  # Set the current real-time value of a database record field.
  #
  # @param [*]              new_value
  # @param [Symbol, String] column    Database field name.
  #
  # @return [*]
  #
  # == Usage Notes
  # If the record is already persisted, this is a direct write which does not
  # trigger validations or callbacks.
  #
  def dynamic_set_field(new_value, column = nil)
    if new_record?
      self[column] = new_value
    else
      update_column(column, new_value)
    end
    new_value
  end

  # Set one or more database record fields in real-time.
  #
  # @param [Hash] values
  #
  # @return [void]
  #
  # == Usage Notes
  # If the record is already persisted, this is a direct write which does not
  # trigger validations or callbacks.
  #
  def dynamic_set_fields(values)
    if new_record?
      values.each_pair { |column, value| self[column] = value }
    else
      update_columns(values)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this record is involved in a workflow step related to
  # the creation of a new EMMA entry.
  #
  def being_created?
    state_group == :create
  end

  # Indicate whether this record is involved in a workflow step related to
  # the modification of an existing EMMA entry.
  #
  def being_modified?
    state_group == :edit
  end

  # Indicate whether this record is involved in a workflow step related to
  # the removal of an existing EMMA entry.
  #
  def being_removed?
    state_group == :remove
  end

  # Indicate whether this record is involved in a workflow step related to
  # the review process.
  #
  def under_review?
    state_group == :review
  end

  # Indicate whether this record is involved in a workflow step related to
  # transmission to a member repository.
  #
  def being_submitted?
    state_group == :submission
  end

  # Indicate whether this record is involved in a workflow step related to
  # ingest into the EMMA Unified Index.
  #
  def being_indexed?
    state_group == :finalization
  end

  # Indicate whether this record is involved in a workflow step related to
  # ingest into the EMMA Unified Index.
  #
  def completed?
    state_group == :done
  end

  # Indicate whether this record is involved in a workflow step which leads
  # to a change in the associated EMMA index entry.
  #
  def in_process?
    being_submitted? || being_indexed?
  end

  # Indicate whether this record is involved in a workflow step where
  # non-administrative data (EMMA or file data) could be changed.
  #
  def unsealed?
    being_created? || being_modified? || being_removed?
  end

  # Indicate whether this record is *not* involved in a workflow step where
  # non-administrative data (EMMA or file data) could be changed.
  #
  def sealed?
    !unsealed?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the group of the given state.
  #
  # @param [String, Symbol] target_state  Default: `#active_state`.
  #
  # @return [Symbol]
  #
  def state_group(target_state = nil)
    target_state ||= active_state
    Upload::WorkflowMethods.state_group(target_state)
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # Return the group of the given state.
  #
  # @param [String, Symbol, nil] target_state
  #
  # @return [Symbol]  Defaults to :create if *target_state* is invalid.
  #
  def self.state_group(target_state)
    REVERSE_STATE_GROUP[target_state&.to_sym] || :create
  end

  # Return the group of the given state.
  #
  # @param [String, Symbol, nil] group
  #
  # @return [String]
  # @return [nil]                     If *group* is invalid.
  #
  def self.state_group_label(group)
    STATE_GROUP.dig(group&.to_sym, :label)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this submission must be reviewed.
  #
  # (If not it can be submitted directly.)
  #
  def review_required?
    DEFAULT_REVIEW_REQUIRED # TODO: review_required?
  end

  # Indicate whether this submission is eligible to be review automatically.
  #
  # (If not it a human reviewer accept it.)
  #
  def auto_reviewable?
    DEFAULT_AUTO_REVIEWABLE # TODO: auto_reviewable?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Start editing a record which is associated with an existing entry by
  # copying the current :emma_data to :edit_emma_data.
  #
  # @param [Hash] opt                 Additional field values to update.
  #
  # @return [Boolean, nil]
  #
  def begin_editing(**opt)
    __debug_args(binding)
    opt[:edit_file_data] ||= nil
    opt[:edit_emma_data] ||= emma_data&.dup
    dynamic_set_fields(opt)
  end

  # Finishing an editing session by updating fields with the information in
  # :edit_file_data and/or :edit_emma_data.
  #
  # @param [Hash] opt                 Additional field values to update.
  #
  # @return [Boolean, nil]
  #
  def finish_editing(**opt)
    __debug_args(binding)
    data = reject_blanks(file_data: edit_file_data, emma_data: edit_emma_data)
    if data.blank?
      Log.warn { "#{__method__}: update with edit data: FAILED (no data)" }
    elsif data.delete_if { |column, value| self[column] == value }.blank?
      Log.info { "#{__method__}: no update: edit data unchanged" }
    else
      opt.merge!(data)
      Log.debug { "##{__method__}: update with edit data: #{opt.inspect}" }
      update(opt.merge!(finishing_edit: true))
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extra information communicated to the Upload form to support reverting
  # the record when backing out of edit changes.
  #
  # @return [Hash{Symbol=>*}]
  #
  attr_accessor :revert_data

  # @type [Array<Symbol>]
  REVERT_DATA_FIELDS = [
    REVERT_FIELDS      = %i[phase state updated_at].freeze,
    REVERT_EDIT_FIELDS = %i[edit_user edit_state edited_at].freeze,
  ].flatten.uniq.freeze

  # Set @revert_data.
  #
  # @return [Hash{Symbol=>*}]
  #
  def set_revert_data
    @revert_data = fields.slice(*REVERT_DATA_FIELDS).compact
  end

  # Safely get @revert_data.
  #
  # @return [Hash{Symbol=>*}]
  #
  def get_revert_data
    @revert_data || {}
  end

end

__loading_end(__FILE__)
