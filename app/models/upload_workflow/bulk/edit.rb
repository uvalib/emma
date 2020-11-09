# app/models/upload_workflow/bulk/edit.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Bulk::Edit < UploadWorkflow::Bulk
  # Initial declaration to establish the namespace.
end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

module UploadWorkflow::Bulk::Edit::Errors
  include UploadWorkflow::Bulk::Errors
end

module UploadWorkflow::Bulk::Edit::Properties
  include UploadWorkflow::Bulk::Properties
  include UploadWorkflow::Bulk::Edit::Errors
end

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Bulk::Edit::External
  include UploadWorkflow::Bulk::External
  include UploadWorkflow::Bulk::Edit::Properties
end

module UploadWorkflow::Bulk::Edit::Data
  include UploadWorkflow::Bulk::Data
  include UploadWorkflow::Bulk::Edit::External
end

module UploadWorkflow::Bulk::Edit::Actions
  include UploadWorkflow::Bulk::Actions
  include UploadWorkflow::Bulk::Edit::Data
end

module UploadWorkflow::Bulk::Edit::Simulation
  include UploadWorkflow::Bulk::Simulation
end

module UploadWorkflow::Bulk::Edit::Simulation
end if UploadWorkflow::Bulk::Edit::SIMULATION

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Bulk::Edit::Events
  include UploadWorkflow::Bulk::Events
end

module UploadWorkflow::Bulk::Edit::Events
  include UploadWorkflow::Bulk::Edit::Simulation
end if UploadWorkflow::Bulk::Edit::WORKFLOW_DEBUG

module UploadWorkflow::Bulk::Edit::States

  include UploadWorkflow::Bulk::States
  include UploadWorkflow::Bulk::Edit::Events
  include UploadWorkflow::Bulk::Edit::Actions

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

    __debug_sim('System presents a form to select control file.')

    unless simulating
      wf_start_submission(*event_args)
    end

    __debug_sim("USER must `cancel!` or `submit!` to advance...")

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
      # From UploadController#bulk_update:
      # succeeded, failed = bulk_upload_edit(data, base_url: url, user: @user)
      __debug_sim('CODE') do
        args = "data=#{submission.data.inspect}"
        opt  = 'base_url: url, user: @user'
        "succeeded, failed = bulk_upload_edit(#{args}, #{opt})"
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
      reject!  # NOTE: => :failed
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
    advance! # NOTE: => :staging
    self
  end

end

# =============================================================================
# :section:
# =============================================================================

public

# Bulk update workflow.
#
class UploadWorkflow::Bulk::Edit < UploadWorkflow::Bulk

  include UploadWorkflow::Bulk::Edit::Events
  include UploadWorkflow::Bulk::Edit::States
  include UploadWorkflow::Bulk::Edit::Transitions

  workflow do

    state :starting do
      event :start,     transitions_to: :starting,    **IF_SYS_DEBUG
      #event :create,    transitions_to: :creating,    **IF_SUBMITTER
      event :edit,      transitions_to: :editing,     **IF_SUBMITTER
      #event :remove,    transitions_to: :removing,    **IF_SUBMITTER
    end

    # =========================================================================
    # = Bulk update =
    # =========================================================================

    state :editing do
      event :cancel,    transitions_to: :canceled,    **IF_USER
      event :submit,    transitions_to: :modifying,   **IF_USER
      #event :upload,    transitions_to: :replacing,   **IF_USER # TODO: remove - not applicable to bulk upload
    end

    state :replacing do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reject,    transitions_to: :editing,     **IF_SYSTEM
      event :cancel,    transitions_to: :canceled,    **IF_USER
      event :advance,   transitions_to: :modifying,   **IF_SYSTEM
    end if false # TODO: remove - not applicable to bulk upload

    state :modifying do
      #event :purge,     transitions_to: :purged,      **IF_ADMIN # TODO: remove - not applicable to bulk upload
      event :reject,    transitions_to: :failed,      **IF_SYSTEM # NOTE: was to :editing
      event :advance,   transitions_to: :modified,    **IF_SYSTEM
    end

    state :modified do
      #event :purge,     transitions_to: :purged,      **IF_ADMIN  # TODO: remove - not applicable to bulk upload
      #event :schedule,  transitions_to: :scheduling,  **IF_SYSTEM # TODO: remove - not applicable to bulk upload
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
      #event :fail,      transitions_to: :failed,      **IF_SYSTEM # TODO: remove - not applicable to bulk upload
      #event :timeout,   transitions_to: :indexing,    **IF_SYSTEM # TODO: remove - not applicable to bulk upload
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
    end if false # TODO: remove - not applicable to bulk upload

    state :failed do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reset,     transitions_to: :starting,    **IF_DEV_DEBUG
      event :resume,    transitions_to: :resuming,    **IF_DEV
    end

    state :canceled do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reset,     transitions_to: :starting,    **IF_DEV_DEBUG
      #event :resume,    transitions_to: :resuming,    **IF_DEV # TODO: remove? # TODO: remove - not applicable to bulk upload
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