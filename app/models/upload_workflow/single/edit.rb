# app/models/upload_workflow/single/edit.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Single::Edit < UploadWorkflow::Single
  include UploadWorkflow::Edit
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
  include UploadWorkflow::Single::Edit::Events
end

module UploadWorkflow::Single::Edit::Data
  include UploadWorkflow::Single::Data
  include UploadWorkflow::Single::Edit::External
end

# New and overridden action methods specific to single-entry update.
#
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
    __debug_items(binding)
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
  # @see UploadWorkflow::External#repository_modify
  #
  def wf_finalize_submission(*event_args)                                       # NOTE: to Action#member_repository_action via Action::Queue#submit! (sorta)
    __debug_items(binding)
    assert_record_present
    record.finish_editing
    if record.emma_native?
      self.succeeded = [record]
    else
      opt = event_args.extract_options!
      s, f = repository_modify(*record, **opt)
      self.succeeded = s
      self.failures += f
    end
    super
  end

  # Canceling an edit requires reverting data fields to their original values
  # which depends on whether the original record was in the :create phase or
  # in the :edit phase (that is, editing a previously edited record).
  #
  # The original field values are supplied to the client form in a hidden
  # 'revert_data' field, which is supplied back to the workflow via the :revert
  # URL parameter when canceling.
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_cancel_submission(*event_args)
    __debug_items(binding)
    opt = event_args.extract_options!&.except(:redirect) || {}
    reset_record(opt)
    if (revert_data = opt[:revert])
      final_phase = revert_data[:phase]
      final_state = revert_data[:state]
      set_workflow_phase(final_phase) if final_phase
      set_workflow_state(final_state) if final_state
      unless final_phase == workflow_column.to_s
        record.set_state(nil, workflow_column)
      end
    end
  end

  # wf_index_update
  #
  # @param [Array] _event_args        Ignored.
  #
  # @return [void]
  #
  # @see UploadWorkflow::Single::External#update_in_index
  #
  def wf_index_update(*_event_args)
    super
    if record.emma_native?
      s, f, _ = update_in_index(*record)
      self.succeeded = s
      self.failures += f
    else
      sid  = record.submission_id.inspect
      repo = Upload.repository_name(record)
      msg  = "Change request #{sid} submitted to #{repo}" # TODO: I18n
      self.succeeded << msg
    end
  end

end

module UploadWorkflow::Single::Edit::Simulation
  include UploadWorkflow::Single::Simulation
end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Single::Edit::Events
  include UploadWorkflow::Single::Events
  include UploadWorkflow::Single::Edit::Simulation
end

# Overridden state transition methods specific to single-entry update.
#
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
        self.succeeded << submission.id
      else
        self.failures  << 'invalid file'
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
      # @item, failed = upload_edit(**data)
      __debug_sim('CODE') do
        args = "data=#{submission.data.inspect}"
        opt  = 'index: false'
        "@item, failed = upload_edit(#{args}, #{opt})"
      end
      bad = nil
      if (db_fail = submission.db_failure)
        self.failures  << 'DB create failed'
      elsif (bad = !(submission.metadata_valid = !submission.invalid_entry))
        self.failures  << 'bad metadata'
      else
        self.succeeded << submission.id
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
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :edit,      transitions_to: :editing,     **IF_SUBMITTER
    end

    # =========================================================================
    # = Modify existing entry (en.emma.upload.state_group.edit)
    # =========================================================================

    state :editing do
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :submit,    transitions_to: :modifying,   **IF_COMPLETE
      event :upload,    transitions_to: :replacing,   **IF_SUBMITTER
    end

    state :replacing do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reject,    transitions_to: :editing
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :submit,    transitions_to: :modifying,   **IF_SUBMITTER
    end

    state :modifying do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reject,    transitions_to: :editing
      event :cancel,    transitions_to: :canceled
      event :advance,   transitions_to: :modified
    end

    state :modified do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :schedule,  transitions_to: :scheduling
      event :advance,   transitions_to: :staging
    end

    # =========================================================================
    # Review sub-sequence (en.emma.upload.state_group.review)
    # =========================================================================

    state :scheduling do
      event :assign,    transitions_to: :assigned
      event :advance,   transitions_to: :assigning
    end

    state :assigning do
      event :hold,      transitions_to: :holding
      event :assign,    transitions_to: :assigned
      event :advance,   transitions_to: :assigned
    end

    state :holding do
      event :edit,      transitions_to: :editing,     **IF_SUBMITTER
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :timeout,   transitions_to: :holding
      event :fail,      transitions_to: :failed
      event :advance,   transitions_to: :assigning
    end

    state :assigned do
      event :edit,      transitions_to: :editing,     **IF_SUBMITTER
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :purge,     transitions_to: :purged
      event :review,    transitions_to: :reviewing,   **IF_REVIEWER
    end

    state :reviewing do
      event :reject,    transitions_to: :rejected,    **IF_REVIEWER
      event :approve,   transitions_to: :approved,    **IF_REVIEWER
    end

    state :rejected do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :edit,      transitions_to: :editing,     **IF_SUBMITTER
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
    end

    state :approved do
      event :advance,   transitions_to: :staging
    end

    # =========================================================================
    # Submission sub-sequence (en.emma.upload.state_group.submission)
    # =========================================================================

    state :staging do
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :index,     transitions_to: :indexing
      event :advance,   transitions_to: :unretrieved
    end

    state :unretrieved do
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :fail,      transitions_to: :failed
      event :timeout,   transitions_to: :unretrieved
      event :advance,   transitions_to: :retrieved
    end

    state :retrieved do
      event :advance,   transitions_to: :indexing
    end

    # =========================================================================
    # Finalization sub-sequence (en.emma.upload.state_group.finalization)
    # =========================================================================

    state :indexing do
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :fail,      transitions_to: :failed
      event :timeout,   transitions_to: :indexing
      event :advance,   transitions_to: :indexed
    end

    state :indexed do
      event :advance,   transitions_to: :completed
    end

    # =========================================================================
    # Terminal states (en.emma.upload.state_group.done)
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
    # Pseudo states (en.emma.upload.state_group.pseudo)
    # =========================================================================

    state :resuming
    state :purged

  end

end

__loading_end(__FILE__)
