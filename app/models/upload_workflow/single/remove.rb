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
      self.failures += f
    else
      sid  = record.submission_id.inspect
      repo = Upload.repository_name(record)
      self.succeeded << "Removal request #{sid} submitted to #{repo}" # TODO: I18n
    end
  end

end

module UploadWorkflow::Single::Remove::Simulation
  include UploadWorkflow::Single::Simulation
end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Single::Remove::Events
  include UploadWorkflow::Single::Events
  include UploadWorkflow::Single::Remove::Simulation
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

    # TODO: simulation - remove
    if simulating
      # From UploadController#delete:
      # ids = Upload.expand_ids(@item_id)
      __debug_sim('CODE') do
        args = "id=#{submission.id.inspect}"
        "@items = Upload.expand_ids(#{args})"
      end
      submission.items << submission.id
    end

    unless simulating
      wf_list_items(*event_args)
    end

    # TODO: simulation - remove
    __debug_sim('System shows the list of item(s) to be removed.')
    if submission&.auto_cancel
      __debug_sim('[auto_remove_cancel: true]')
      __debug_sim('USER decides not to delete item(s).')
      cancel! # NOTE: => :canceled
    elsif submission&.auto_submit
      __debug_sim('[auto_remove_submit: true]')
      __debug_sim('USER confirms the intent to delete item(s).')
      submit! # NOTE: => :removed
    else
      __debug_sim('USER must `cancel!` or `submit!` to advance...')
    end

    self
  end

  # Upon entering the :removed state:
  #
  # The removal request is created.
  #
  # For EMMA-native items this causes the items to be removed directly.
  #
  # For member repository items this causes a removal request to be staged.
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

    # TODO: simulation - remove
    if simulating
      __debug_sim("[remove_emma_items: #{submission.emma_item}]")
      emma_items = submission.emma_item
    else
      emma_items = true
    end

    # Determine whether this is destined for a member repository.
    unless simulating
      emma_items = Upload.emma_native?(record) if record
    end

    ok = nil

    if simulating
      if emma_items
        # From UploadController#destroy:
        # succeeded, failed = bulk_upload_remove(items)
        __debug_sim('CODE') do
          args = "items=#{submission.items.inspect}"
          opt  = 'index: false'
          "succeeded, failed = bulk_upload_remove(#{args}, #{opt})"
        end
        self.succeeded += submission.items
        ok = ready?
      else
        ok = true # TODO: Simulate member repository delete request?
      end
    end

    unless simulating
      wf_remove_items(*event_args)
      ok = ready?
    end

    # TODO: simulation - remove
    __debug_sim do
      if !emma_items; 'Generating removal request for member repository items.'
      elsif !ok;      'The EMMA-native items NOT removed due to failure(s).'
      else;           'The EMMA-native items were removed.'; end
    end

    # Automatically transition to the next state based on submission status.
    if ok
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
