# app/models/upload_workflow/bulk/remove.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Bulk::Remove < UploadWorkflow::Bulk
  include UploadWorkflow::Remove
end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

module UploadWorkflow::Bulk::Remove::Errors
  include UploadWorkflow::Bulk::Errors
end

module UploadWorkflow::Bulk::Remove::Properties
  include UploadWorkflow::Bulk::Properties
  include UploadWorkflow::Bulk::Remove::Errors
end

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Bulk::Remove::External
  include UploadWorkflow::Bulk::External
  include UploadWorkflow::Bulk::Remove::Properties
  include UploadWorkflow::Bulk::Remove::Events
end

module UploadWorkflow::Bulk::Remove::Data
  include UploadWorkflow::Bulk::Data
  include UploadWorkflow::Bulk::Remove::External
end

module UploadWorkflow::Bulk::Remove::Actions

  include UploadWorkflow::Bulk::Actions
  include UploadWorkflow::Bulk::Remove::Data

  # ===========================================================================
  # :section: UploadWorkflow::Actions overrides
  # ===========================================================================

  public

  # wf_validate_submission
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  def wf_validate_submission(*event_args)
    __debug_items(binding)
    wf_list_items(*event_args)
  end

end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Bulk::Remove::Events
  include UploadWorkflow::Bulk::Events
end

# Overridden state transition methods specific to bulk removal.
#
module UploadWorkflow::Bulk::Remove::States

  include UploadWorkflow::Bulk::States
  include UploadWorkflow::Bulk::Remove::Events
  include UploadWorkflow::Bulk::Remove::Actions

  # ===========================================================================
  # :section: UploadWorkflow::States overrides
  # ===========================================================================

  public

  # Upon entering the :removing state:
  #
  # The user is presented with a request for confirmation that the item
  # should be submitted for removal.
  #
  # The workflow remains in this state until the user either cancels or
  # submits to confirm removal of the indicated item(s).
  #
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_removing_entry(state, event, *event_args)
    super
    #__debug_wf 'System shows the list of item(s) to be removed.'

    wf_validate_submission(*event_args)

    #__debug_wf 'USER must `cancel!` or `submit!` to advance...'
    self
  end

  # Upon entering the :removed state:
  #
  # The removal request is created.
  #
  # For EMMA-native items this causes the items to be removed directly.
  #
  # For partner repository items this causes a removal request to be staged.
  #
  # Transition out of this workflow state happens automatically; in the case
  # of EMMA-native items, the next state depends upon the success of the
  # requested removal.
  #
  #
  # @param [Workflow::State] state        State that is being entered.
  # @param [Symbol]          event        Triggering event
  # @param [Array]           event_args
  #
  # @return [self]                        Return *self* for chaining.
  #
  def on_removed_entry(state, event, *event_args)
    super

    # Determine whether this is destined for a partner repository.
    #emma_items = true
    #emma_items = Upload.emma_native?(record) if record

    wf_remove_items(*event_args)
    valid = ready?

=begin # NOTE: workflow debugging
    __debug_wf do
      if emma_items && valid
        'The EMMA-native items were removed.'
      elsif emma_items
        'The EMMA-native items NOT removed due to failure(s).'
      else
        'Generating removal request for partner repository items'
      end
    end
=end

    # Automatically transition to the next state based on submission status.
    if valid
      advance! # NOTE: => :staging
    else
      fail!    # NOTE: => :failed
    end
    self
  end

end

# =============================================================================
# :section:
# =============================================================================

public

# Bulk removal workflow.
#
class UploadWorkflow::Bulk::Remove < UploadWorkflow::Bulk

  include UploadWorkflow::Bulk::Remove::Events
  include UploadWorkflow::Bulk::Remove::States
  include UploadWorkflow::Bulk::Remove::Transitions

  workflow do

    state :starting do
      event :start,     transitions_to: :starting,    **IF_SYS_DEBUG
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :remove,    transitions_to: :removing,    **IF_SUBMITTER
    end

    # =========================================================================
    # = Bulk delete (en.emma.upload.state_group.remove)
    # =========================================================================

    state :removing do
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :submit,    transitions_to: :removed,     **IF_SUBMITTER
    end

    state :removed do
      event :fail,      transitions_to: :failed
      event :advance,   transitions_to: :staging
    end

    # =========================================================================
    # Submission sub-sequence (en.emma.upload.state_group.submission)
    # =========================================================================

    state :staging do
      event :index,     transitions_to: :indexing
      event :advance,   transitions_to: :unretrieved
    end

    state :unretrieved do
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
      event :advance,   transitions_to: :indexed
    end

    state :indexed do
      event :advance,   transitions_to: :completed
    end

    # =========================================================================
    # Terminal states (en.emma.upload.state_group.done)
    # =========================================================================

    state :failed do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reset,     transitions_to: :starting,    **IF_DEV_DEBUG
      event :resume,    transitions_to: :resuming,    **IF_DEV
    end

    state :canceled do
      event :purge,     transitions_to: :purged,      **IF_ADMIN
      event :reset,     transitions_to: :starting,    **IF_DEV_DEBUG
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
