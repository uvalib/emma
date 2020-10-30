# app/models/upload_workflow/single/edit.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Single::Edit < UploadWorkflow::Single

  # The 'uploads' table field associated with workflow state for workflows
  # involving modification of existing entries.
  #
  # @type [Symbol]
  #
  STATE_COLUMN = Upload::SECONDARY_STATE_COLUMN

end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

module UploadWorkflow::Single::Edit::Errors
  include UploadWorkflow::Single::Errors
end

module UploadWorkflow::Single::Edit::Properties
  include UploadWorkflow::Single::Properties
  include UploadWorkflow::Single::Edit::Errors
end

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Single::Edit::External
  include UploadWorkflow::Single::External
  include UploadWorkflow::Single::Edit::Properties
end

module UploadWorkflow::Single::Edit::Data
  include UploadWorkflow::Single::Data
  include UploadWorkflow::Single::Edit::External
end

module UploadWorkflow::Single::Edit::Actions

  include UploadWorkflow::Single::Actions
  include UploadWorkflow::Single::Edit::Data

  # ===========================================================================
  # :section: UploadWorkflow::Actions overrides
  # ===========================================================================

  public

  # wf_start_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::Single::Data#set_record
  # @see Upload#begin_editing
  #
  def wf_start_submission(*event_args)
    __debug_args(binding)
    super
    record.begin_editing
  end

  # wf_finalize_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see Upload#finish_editing
  # @see UploadWorkflow::External#repository_edit
  #
  def wf_finalize_submission(*event_args)
    __debug_args(binding)
    assert_record_present
    record.finish_editing
    if record.emma_native?
      @succeeded = record
    else
      opt = event_args.last.is_a?(Hash) ? event_args.last : {}
      @succeeded, @failed =
        repository_edit(record.repository, *record, **opt)
    end
    super
  end

  # wf_cancel_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_cancel_submission(*event_args)
    __debug_args(binding)
    opt = event_args.extract_options! || {}
    revert_phase = (record.edit_file_data != record.file_data)
    super(*event_args, opt.merge(reset: true))
    set_workflow_phase(:create) if revert_phase
  end

end

module UploadWorkflow::Single::Edit::Simulation
  include UploadWorkflow::Single::Simulation
end

module UploadWorkflow::Single::Edit::Simulation
end if UploadWorkflow::Single::Edit::SIMULATION

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Single::Edit::Events
  include UploadWorkflow::Single::Events
end

module UploadWorkflow::Single::Edit::Events
  include UploadWorkflow::Single::Edit::Simulation
end if UploadWorkflow::Single::Edit::WORKFLOW_DEBUG

module UploadWorkflow::Single::Edit::States

  include UploadWorkflow::Single::States
  include UploadWorkflow::Single::Edit::Events
  include UploadWorkflow::Single::Edit::Actions

  # ===========================================================================
  # :section: UploadWorkflow::States overrides
  # ===========================================================================

  public

  # Upon entering the :editing state:
  #
  # The user is presented with the edit form pre-populated with
  # previously-provided values.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_editing_entry(state, event, *event_args)
    super

    # TODO: simulation - remove
    if simulating
      action =
        case existing_record
          when false then :set_record
          when true  then :reset_record
          else            :create_record
        end
      if action == :create_record
        # From UploadController#edit:
        # @item = (get_record(@item_id) unless show_menu?(@item_id))
        __debug_sim('CODE') do
          args = "id=#{submission.id.inspect}"
          "@item = get_record(#{args})"
        end
        submission.set_item
      else
        action = :set_record
      end
    else
      action = :create_record
    end

    unless simulating
      wf_start_submission(*event_args)
    end

    # TODO: simulation - remove
    __debug_sim do
      case action
        when :set_record   then 'Form error message displayed if present.'
        when :reset_record then 'Edit form reset after cancel.'
        else                    'System presents a pre-populated edit form.'
      end
    end

    # TODO: simulation - remove
    commit = file_valid? ? 'submit' : 'upload'
    __debug_sim('USER modifies form to enable submit.')
    __debug_sim("USER must `cancel!` or `#{commit}!` to advance...")

    self
  end

  # Upon entering the :replacing state:
  #
  # The supplied replacement file is being validated.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_replacing_entry(state, event, *event_args)
    super

    __debug_sim('The uploaded file is received in the Shrine cache.')

    # Verify validity of the uploaded file. # TODO: simulation - remove
    if simulating
      # From UploadController#endpoint:
      # stat, hdrs, body = FileUploader.upload_response(:cache, request.env)
      __debug_sim('CODE') do
        args = ':cache, request.env'
        "FileUploader.upload_response(#{args})"
      end
      __debug_sim("[edit_invalid_file: #{submission.invalid_file}]")
      submission.file_valid = !submission.invalid_file
      if submission.file_valid
        @succeeded << submission.id
      else
        @failed << 'invalid file'
      end
    end

    # Verify validity of the uploaded file.
    unless simulating
      wf_upload_file(*event_args)
    end

    valid = ready?

    # TODO: simulation - remove
    if valid
      __debug_sim('The remediated file was determined to be VALID.')
      __debug_sim('The form is populated with extracted metadata.')
      __debug_sim('USER may modify metadata fields.')
      __debug_sim('USER must `cancel!` or `submit!` to advance...')
    else
      __debug_sim('The remediated file was determined to be INVALID.')
      __debug_sim('System generates a form error message to be displayed.')
    end

    # If the file is valid then the submission remains in this state until
    # the user completes and submits the form, or cancels the submission.
    reject! unless valid # NOTE: => :editing
    self
  end

  # Upon entering the :modifying state:
  #
  # The modified submission is complete and ready to move into the submission
  # queue.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_modifying_entry(state, event, *event_args)
    super

    # Verify validity of the submission. # TODO: simulation - remove
    if simulating
      # From UploadController#update:
      # @item, @failed = upload_edit(**data)
      __debug_sim('CODE') do
        args = "data=#{submission.data.inspect}"
        opt  = 'index: false'
        "@item, @failed = upload_edit(#{args}, #{opt})"
      end
      bad = nil
      if (db_fail = submission.db_failure)
        @failed << 'DB create failed'
      elsif (bad = !(submission.metadata_valid = !submission.invalid_entry))
        @failed << 'bad metadata'
      else
        @succeeded << submission.id
      end
      if db_fail
        __debug_sim('[edit_db_failure: true]')
        __debug_sim('The database entry could not be updated.')
      elsif bad
        __debug_sim('[edit_invalid_entry: true]')
        __debug_sim('The entry is invalid/incomplete.')
        __debug_sim('(NOTE: PROBABLE FAILURE OF CLIENT-SIDE FORM VALIDATION)')
      else
        __debug_sim('[edit_invalid_entry: false]')
        __debug_sim('[edit_db_failure:    false]')
      end
    end

    # Verify validity of the submission.
    unless simulating
      wf_validate_submission(*event_args)
    end

    valid = ready?

    # TODO: simulation - remove
    if valid
      __debug_sim('The database entry was updated.')
    else
      __debug_sim('System generates a form error message to be displayed.')
    end

    # Automatically transition to the next state based on submission status.
    if valid
      advance! # NOTE: => :modified
    else
      reject!  # NOTE: => :editing
    end
    self
  end

  # Upon entering the :modified state:
  #
  # The modified submission is moving into the submission queue.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_modified_entry(state, event, *event_args)
    super

    # TODO: simulation - remove
    if simulating
      __debug_sim("[edit_no_review: #{submission.no_review}]")
      must_review = !submission.no_review
    else
      must_review = true
    end

    # Determine whether the item needs to be reviewed.
    unless simulating
      must_review = record.review_required? if record
    end

    # TODO: simulation - remove
    if must_review
      __debug_sim('This item requires review.')
    else
      __debug_sim('This item can be submitted without review.')
    end

    # Automatically transition to the next state based on submission status.
    if must_review
      schedule! # NOTE: => :scheduling
    else
      advance!  # NOTE: => :staging
    end
    self
  end

end

# =============================================================================
# :section:
# =============================================================================

public

# Single-entry update workflow.
#
class UploadWorkflow::Single::Edit < UploadWorkflow::Single

  include UploadWorkflow::Single::Edit::Events
  include UploadWorkflow::Single::Edit::States
  include UploadWorkflow::Single::Edit::Transitions

  workflow do

    state :starting do
      event :start,     transitions_to: :starting,    **IF_SYS_DEBUG
      #event :create,    transitions_to: :creating,    **IF_SUBMITTER
      event :edit,      transitions_to: :editing,     **IF_SUBMITTER
      #event :remove,    transitions_to: :removing,    **IF_SUBMITTER
    end

    # =========================================================================
    # = Modify existing entry =
    # =========================================================================

    state :editing do
      event :cancel,    transitions_to: :canceled,    **IF_USER
      event :submit,    transitions_to: :modifying,   **IF_COMPLETE
      event :upload,    transitions_to: :replacing,   **IF_USER
    end

    state :replacing do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reject,    transitions_to: :editing,     **IF_SYSTEM
      event :cancel,    transitions_to: :canceled,    **IF_USER
      event :submit,    transitions_to: :modifying,   **IF_USER
    end

    state :modifying do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reject,    transitions_to: :editing,     **IF_SYSTEM
      event :advance,   transitions_to: :modified,    **IF_SYSTEM
    end

    state :modified do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :schedule,  transitions_to: :scheduling,  **IF_SYSTEM
      event :advance,   transitions_to: :staging,     **IF_SYSTEM
    end

    # =========================================================================
    # Sub-sequence: Review
    # =========================================================================

    state :scheduling do
      event :assign,    transitions_to: :assigned,    **IF_SYSTEM
      event :advance,   transitions_to: :assigning,   **IF_SYSTEM
    end

    state :assigning do
      event :hold,      transitions_to: :holding,     **IF_SYSTEM
      event :assign,    transitions_to: :assigned,    **IF_SYSTEM
      event :advance,   transitions_to: :assigned,    **IF_SYSTEM
    end

    state :holding do
      event :edit,      transitions_to: :editing,     **IF_USER
      event :cancel,    transitions_to: :canceled,    **IF_USER
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :timeout,   transitions_to: :holding,     **IF_SYSTEM
      event :fail,      transitions_to: :failed,      **IF_SYSTEM
      event :advance,   transitions_to: :assigning,   **IF_SYSTEM
    end

    state :assigned do
      event :edit,      transitions_to: :editing,     **IF_USER
      event :cancel,    transitions_to: :canceled,    **IF_USER
      event :purge,     transitions_to: :purged,      **IF_SYSTEM
      event :review,    transitions_to: :reviewing,   **IF_REVIEWER
    end

    state :reviewing do
      event :reject,    transitions_to: :rejected,    **IF_REVIEWER
      event :approve,   transitions_to: :approved,    **IF_REVIEWER
    end

    state :rejected do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :edit,      transitions_to: :editing,     **IF_USER
      event :cancel,    transitions_to: :canceled,    **IF_USER
    end

    state :approved do
      event :advance,   transitions_to: :staging,     **IF_SYSTEM
    end

    # =========================================================================
    # Sub-sequence: Submission
    # =========================================================================

    state :staging do
      event :index,     transitions_to: :indexing,    **IF_SYSTEM
      event :advance,   transitions_to: :unretrieved, **IF_SYSTEM
    end

    state :unretrieved do
      event :fail,      transitions_to: :failed,      **IF_SYSTEM
      event :timeout,   transitions_to: :unretrieved, **IF_SYSTEM
      event :advance,   transitions_to: :retrieved,   **IF_SYSTEM
    end

    state :retrieved do
      event :advance,   transitions_to: :indexing,    **IF_SYSTEM
    end

    # =========================================================================
    # Sub-sequence: Finalization
    # =========================================================================

    state :indexing do
      event :fail,      transitions_to: :failed,      **IF_SYSTEM
      event :timeout,   transitions_to: :indexing,    **IF_SYSTEM
      event :advance,   transitions_to: :indexed,     **IF_SYSTEM
    end

    state :indexed do
      event :advance,   transitions_to: :completed,   **IF_SYSTEM
    end

    # =========================================================================
    # Sub-sequence: Termination
    # =========================================================================

    state :suspended do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reset,     transitions_to: :starting,    **IF_DEV_DEBUG
      event :resume,    transitions_to: :resuming,    **IF_DEV
    end

    state :failed do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reset,     transitions_to: :starting,    **IF_DEV_DEBUG
      event :resume,    transitions_to: :resuming,    **IF_DEV
    end

    state :canceled do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reset,     transitions_to: :starting,    **IF_DEV_DEBUG
      event :resume,    transitions_to: :resuming,    **IF_DEV # TODO: remove?
    end

    state :completed do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reset,     transitions_to: :starting,    **IF_DEV_DEBUG
      event :edit,      transitions_to: :editing,     **IF_SUBMITTER
    end

    # =========================================================================
    # Pseudo states
    # =========================================================================

    state :resuming
    state :purged

  end

end

__loading_end(__FILE__)
