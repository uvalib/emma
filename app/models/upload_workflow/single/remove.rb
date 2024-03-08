# app/models/upload_workflow/single/remove.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Single::Remove < UploadWorkflow::Single
  include UploadWorkflow::Remove
end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

module UploadWorkflow::Single::Remove::Errors
  include UploadWorkflow::Single::Errors
end

module UploadWorkflow::Single::Remove::Properties
  include UploadWorkflow::Single::Properties
  include UploadWorkflow::Single::Remove::Errors
end

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Single::Remove::External
  include UploadWorkflow::Single::External
  include UploadWorkflow::Single::Remove::Properties
  include UploadWorkflow::Single::Remove::Events
end

module UploadWorkflow::Single::Remove::Data
  include UploadWorkflow::Single::Data
  include UploadWorkflow::Single::Remove::External
end

# New and overridden action methods specific to single-entry removal.
#
module UploadWorkflow::Single::Remove::Actions

  include UploadWorkflow::Single::Actions
  include UploadWorkflow::Single::Remove::Data

  # ===========================================================================
  # :section: UploadWorkflow::Actions overrides
  # ===========================================================================

  public

  # wf_index_update
  #
  # @param [Array] _event_args        Ignored.
  #
  # @return [void]
  #
  # @see UploadWorkflow::Single::External#remove_from_index
  #
  def wf_index_update(*_event_args)
    super
    if record.emma_native?
      s, f, _ = remove_from_index(*record)
      self.succeeded = s
      self.failures.concat(f)
    else
      sid  = record.submission_id.inspect
      repo = Upload.repository_name(record)
      msg  = config_text(:upload, :non_native, :remove, sid: sid, repo: repo)
      self.succeeded << msg
    end
  end

end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Single::Remove::Events
  include UploadWorkflow::Single::Events
end

# Overridden state transition methods specific to single-entry removal.
#
module UploadWorkflow::Single::Remove::States

  include UploadWorkflow::Single::States
  include UploadWorkflow::Single::Remove::Events
  include UploadWorkflow::Single::Remove::Actions

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

    wf_list_items(*event_args)

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

=begin
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

# Single-entry removal workflow.
#
class UploadWorkflow::Single::Remove < UploadWorkflow::Single

  include UploadWorkflow::Single::Remove::Events
  include UploadWorkflow::Single::Remove::States
  include UploadWorkflow::Single::Remove::Transitions

  workflow do

    state :starting do
      event :start,     transitions_to: :starting,    **IF_SYS_DEBUG
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :remove,    transitions_to: :removing,    **IF_SUBMITTER
    end

    # =========================================================================
    # = Remove existing entry (en.emma.upload.state_group.remove)
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
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
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
