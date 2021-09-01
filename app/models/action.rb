# app/models/action.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An 'actions' table record which is used by a (possibly asynchronous) process
# to track execution of a specific action involving an Entry.
#
# @!attribute [r]  phase_id
#   The workflow instance this action is a part of.
#
# @!attribute [r]  user_id
#   The user who initiated the action.
#
# @!attribute [rw] command
#   Control command to be honored by the workflow process using this instance.
#
# @!attribute [r]  type
#   Action STI subclass.
#
# @!attribute [rw] state
#   Action::*.state_values
#
# @!attribute [rw] condition
#   Action.condition_values
#
# @!attribute [rw] action
#   Current action in progress.
#
# @!attribute [rw] report
#   Latest error message from action.
#
# @!attribute [rw] retries
#   Current retry; 0 for initial execution.
#
# @!attribute [rw] emma_data
#   JSON metadata extracted from the file.
#   (Action::Store only)
#
# @!attribute [rw] file_data
#   Shrine metadata for the file.
#   (Action::Store only)
#
# @!attribute [rw] file_source
#   URI origin of the file (unless uploaded directly).
#   (Action::Store only)
#   TODO: probably want to push this into :file_data
#
# @!attribute [rw] checksum
#   File checksum (for detecting file change)
#   (Action::Store only)
#   TODO: probably want to push this into :file_data
#
# @!attribute [r]  created_at
#   Time of record creation.
#
# @!attribute [rw] updated_at
#   Last time record was modified.
#
class Action < ApplicationRecord

  DESTRUCTIVE_TESTING = false

  include Model

  include Record
  include Record::Sti::Root
  include Record::Bulk::Root
  include Record::Assignable
  include Record::Authorizable
  include Record::Controllable
  include Record::Describable
  include Record::Reportable
  include Record::Submittable
  include Record::Updatable

  include Record::Testing
  include Record::Debugging

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Controllable::CommandMethods
    include Record::Controllable::ConditionMethods
    extend  Record::Describable::ClassMethods
    # :nocov:
  end

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  belongs_to :user,  optional: true
  belongs_to :phase, optional: true

  has_one :entry, through: :phase

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Record::Submittable methods for IngestService operations.
  #
  # @type [Hash{Symbol=>Symbol,Proc}]
  #
  INGEST_METHODS = {
    delete_records: :remove_from_index,
    put_records:    ->(target) {
      target.new_submission? ? :add_to_index : :update_in_index                 # TODO: NOTE: currently a problem because these methods expect an Entry not a Model
    },
  }.freeze

  # Invoke the given IngestService method.
  #
  # @param [Symbol]                    meth         Service method.
  # @param [Hash{Symbol=>Symbol,Proc}] method_map
  #
  # @return [Boolean]                 True if there were no errors.
  #
  def ingest_action(meth, method_map: INGEST_METHODS, **)
    external_action do |target|
      _succeeded, failed, _rollback =
        if method_map[meth]
          # Invoke the related Record::Submittable method.
          meth = method_map[meth]
          meth = meth.call(target) if meth.is_a?(Proc)
          send(meth, target)
        else
          # Invoke the service method directly.
          result = ingest_api.send(meth, target)
          process_ingest_errors(result, target)
        end
      failed
    end
  end

  # Record::Submittable methods for AwsS3Service operations.
  #
  # @type [Hash{Symbol=>Symbol,Proc}]
  #
  REPOSITORY_METHODS = {
    creation_request:     :repository_create,
    modification_request: :repository_modify,
    removal_request:      :repository_remove,
    dequeue:              :repository_dequeue
  }.freeze

  # Invoke the given AwsS3Service method.
  #
  # @param [Symbol]                    meth         Service method.
  # @param [Hash{Symbol=>Symbol,Proc}] method_map
  #
  # @return [Boolean]                 True if there were no errors.
  #
  def member_repository_action(meth, method_map: REPOSITORY_METHODS, **)
    external_action do |target|
      _succeeded, failed =
        if method_map[meth]
          # Invoke the related Record::Submittable method.
          meth = method_map[meth]
          meth = meth.call(target) if meth.is_a?(Proc)
          send(meth, target)
        else
          # Invoke the service method directly.
          result = aws_api.send(meth, target)
          process_aws_errors(result, target)
        end
      failed
    end
  end

  # external_action
  #
  # @return [Boolean]                 True if there were no errors.
  #
  # @yield [target]
  # @yieldparam [Phase, Action] target
  # @yieldreturn [ExecReport, Array<String>]
  #
  def external_action
    target = self
    errors = yield(target)
    if errors.present?
      set_exec_report(errors)
      failed!
    end
    errors.blank?
  end

  # ===========================================================================
  # :section: Record::Describable overrides
  # ===========================================================================

  public

  # A textual description of the type of the Model instance.
  #
  # @param [Action] action
  # @param [Hash]  opt
  #
  # @return [String]
  #
  def self.describe_type(action, **opt)
    (opt[:type] || action&.type_value || 'unknown action').to_s # TODO: I18n
  end

  # A textual description of the status of the Action instance.
  #
  # @param [Action] action
  # @param [Hash]   opt
  #
  # @option opt [String]              :note
  # @option opt [Symbol, String, nil] :state  If *nil*, do not append state.
  # @option opt [Symbol, String]      :type   Default: `action.type_value`
  #
  # @return [String]
  #
  def self.describe_status(action, **opt)
    note   = opt.delete(:note) || describe_type(action, **opt)
    note   = process_note(note, action, **opt)
    status = opt.key?(:state) ? opt[:state] : action.state_description
    [note, status].compact_blank.join(' - ')
  end

  # ===========================================================================
  # :section: Record::Debugging overrides
  # ===========================================================================

  public

  if DEBUG_RECORD

    def show
      super(:user, :phase, :entry)
    end

  end

end

# =============================================================================
# Pre-load Action subclasses for easier TRACE_LOADING.
# =============================================================================

require_subclasses(__FILE__)

__loading_end(__FILE__)
