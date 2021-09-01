# app/models/upload_workflow/single/create.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Single::Create < UploadWorkflow::Single
  include UploadWorkflow::Create
end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

module UploadWorkflow::Single::Create::Errors
  include UploadWorkflow::Single::Errors
end

module UploadWorkflow::Single::Create::Properties
  include UploadWorkflow::Single::Properties
  include UploadWorkflow::Single::Create::Errors
end

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Single::Create::External
  include UploadWorkflow::Single::External
  include UploadWorkflow::Single::Create::Properties
  include UploadWorkflow::Single::Create::Events
end

module UploadWorkflow::Single::Create::Data
  include UploadWorkflow::Single::Data
  include UploadWorkflow::Single::Create::External
end

# New and overridden action methods specific to single-entry submission.
#
module UploadWorkflow::Single::Create::Actions

  include UploadWorkflow::Single::Actions
  include UploadWorkflow::Single::Create::Data

  # ===========================================================================
  # :section: UploadWorkflow::Actions overrides
  # ===========================================================================

  public

  # wf_finalize_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::External#repository_create
  #
  def wf_finalize_submission(*event_args)                                       # NOTE: to Action#member_repository_action via Action::Queue#submit! (sorta)
    __debug_items(binding)
    assert_record_present
    if record.emma_native?
      self.succeeded = [record]
    else
      opt = event_args.last.is_a?(Hash) ? event_args.last : {}
      s, f = repository_create(*record, **opt)
      self.succeeded = s
      self.failures += f
    end
    super
  end

  # wf_cancel_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::Single::Actions#wf_remove_items
  #
  def wf_cancel_submission(*event_args)
    __debug_items(binding)
    opt = event_args.extract_options!&.except(:redirect) || {}
    opt.reverse_merge!(index: false, force: false)
    wf_remove_items(*event_args, opt)
  end

  # wf_index_update
  #
  # @param [Array] _event_args        Ignored.
  #
  # @return [void]
  #
  # @see UploadWorkflow::Single::External#add_to_index
  #
  def wf_index_update(*_event_args)
    super
    if record.emma_native?
      s, f, _ = add_to_index(*record)
      self.succeeded = s
      self.failures += f
    else
      sid  = record.submission_id.inspect
      repo = Upload.repository_name(record)
      self.succeeded << "Request #{sid} submitted to #{repo}" # TODO: I18n
    end
  end

end

module UploadWorkflow::Single::Create::Simulation
  include UploadWorkflow::Single::Simulation
end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Single::Create::Events
  include UploadWorkflow::Single::Events
  include UploadWorkflow::Single::Create::Simulation
end

# Overridden state transition methods specific to single-entry submission.
#
module UploadWorkflow::Single::Create::States

  include UploadWorkflow::Single::States
  include UploadWorkflow::Single::Create::Events
  include UploadWorkflow::Single::Create::Actions

  # ===========================================================================
  # :section: UploadWorkflow::States overrides
  # ===========================================================================

  public

  # Upon entering the :creating state:
  #
  # The user is presented with the form for submitting a new item.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_creating_entry(state, event, *event_args)
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
        # From UploadController#new:
        # @item = new_record(user_id: @user.id, base_url: request.base_url)
        __debug_sim('CODE') do
          args = 'user_id: @user.id, base_url: request.base_url'
          "@item = new_record(#{args})"
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
        when :reset_record then 'New-item form emptied after cancel.'
        else                    'System presents a new-item submission form.'
      end
    end

    # TODO: simulation - remove
    commit = file_valid? ? 'submit' : 'upload'
    __debug_sim('USER fills form until submit is enabled.')
    __debug_sim("USER must `cancel!` or `#{commit}!` to advance...")

    self
  end

  # Upon entering the :validating state:
  #
  # The supplied file is being validated.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_validating_entry(state, event, *event_args)
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
      __debug_sim("[invalid_file: #{submission.invalid_file}]")
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
      __debug_sim('USER continues to fill form until submit is enabled.')
      __debug_sim('USER must `cancel!` or `submit!` to advance...')
    else
      __debug_sim('The remediated file was determined to be INVALID.')
      __debug_sim('System generates a form error message to be displayed.')
    end

    # If the file is valid then the submission remains in this state until
    # the user completes and submits the form, or cancels the submission.
    reject! unless valid # NOTE: => :creating

    self
  end

  # Upon entering the :submitting state:
  #
  # The submission is complete and ready to move into the submission queue.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_submitting_entry(state, event, *event_args)
    super

    # Verify validity of the submission. # TODO: simulation - remove
    if simulating
      # From UploadController#create:
      # @item, failed = upload_create(data)
      __debug_sim('CODE') do
        args = "data=#{submission.data.inspect}"
        opt  = 'index: false'
        "@item, failed = upload_create(#{args}, #{opt})"
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
        __debug_sim('[db_failure: true]')
        __debug_sim('The database entry could not be created.')
      elsif bad
        __debug_sim('[invalid_entry: true]')
        __debug_sim('The entry is invalid/incomplete.')
        __debug_sim('(NOTE: PROBABLE FAILURE OF CLIENT-SIDE FORM VALIDATION)')
      else
        __debug_sim('[invalid_entry: false]')
        __debug_sim('[db_failure:    false]')
      end
    end

    # Verify validity of the submission.
    unless simulating
      wf_validate_submission(*event_args)
    end

    valid = ready?

    # TODO: simulation - remove
    if valid
      __debug_sim('The database entry was created.')
    else
      __debug_sim('System generates a form error message to be displayed.')
    end

    # Automatically transition to the next state based on submission status.
    if valid
      advance! # NOTE: => :submitted
    else
      reject!  # NOTE: => :creating
    end
    self
  end

  # Upon entering the :submitted state:
  #
  # The submission is moving into the submission queue.
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_submitted_entry(state, event, *event_args)
    super

    # TODO: simulation - remove
    if simulating
      __debug_sim("[no_review: #{submission.no_review}]")
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

# Single-entry submission workflow.
#
class UploadWorkflow::Single::Create < UploadWorkflow::Single

  include UploadWorkflow::Single::Create::Events
  include UploadWorkflow::Single::Create::States
  include UploadWorkflow::Single::Create::Transitions

  workflow do

    state :starting do
      event :start,     transitions_to: :starting,    **IF_SYS_DEBUG
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :create,    transitions_to: :creating,    **IF_SUBMITTER
    end

    # =========================================================================
    # = Create new entry (en.emma.upload.state_group.create)
    # =========================================================================

    state :creating do
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :submit,    transitions_to: :submitting,  **IF_COMPLETE
      event :upload,    transitions_to: :validating,  **IF_SUBMITTER
    end

    state :validating do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reject,    transitions_to: :creating
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :submit,    transitions_to: :submitting,  **IF_SUBMITTER
    end

    state :submitting do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reject,    transitions_to: :creating
      event :cancel,    transitions_to: :canceled
      event :advance,   transitions_to: :submitted
    end

    state :submitted do
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
      event :edit,      transitions_to: :creating,    **IF_SUBMITTER
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :timeout,   transitions_to: :holding
      event :fail,      transitions_to: :failed
      event :advance,   transitions_to: :assigning
    end

    state :assigned do
      event :edit,      transitions_to: :creating,    **IF_SUBMITTER
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
      event :edit,      transitions_to: :creating,    **IF_SUBMITTER
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
    end

    # =========================================================================
    # Pseudo states (en.emma.upload.state_group.pseudo)
    # =========================================================================

    state :resuming
    state :purged

  end

end

__loading_end(__FILE__)
