# app/models/upload_workflow/bulk/edit.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Bulk::Edit < UploadWorkflow::Bulk
  include UploadWorkflow::Edit
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
  include UploadWorkflow::Bulk::Edit::Events
end

module UploadWorkflow::Bulk::Edit::Data
  include UploadWorkflow::Bulk::Data
  include UploadWorkflow::Bulk::Edit::External
end

# New and overridden action methods specific to bulk update.
#
module UploadWorkflow::Bulk::Edit::Actions

  include UploadWorkflow::Bulk::Actions
  include UploadWorkflow::Bulk::Edit::Data

  # This should be *false* in order to get the full benefit of batch operation.
  #
  # If this is *true* then it essentially defeats batching by segregating
  # editing activities (download, upload, database) into one phase, and
  # indexing into the following phase.  Batching occurs in each phase, but the
  # entire set of entries must pass through one phase before entering the next.
  #
  # @type [Boolean]
  #
  DEFER_INDEXING = false

  # ===========================================================================
  # :section: UploadWorkflow::Actions overrides
  # ===========================================================================

  public

  # This action basically runs the bulk edit to completion.
  #
  # Since there are no review workflow steps, and indexing has to be done for
  # each batch in order to support the notion of batching, then the bulk-edit
  # workflow is "validated" by completing it and reporting on the
  # successes/failures of the overall process.
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::Bulk::External#bulk_upload_edit
  #
  def wf_validate_submission(*event_args)
    __debug_items(binding)
    opt = event_args.extract_options!.dup
    opt[:index]        = false if DEFER_INDEXING && !opt.key?(:index)
    opt[:user]       ||= current_user
    opt[:base_url]   ||= nil #request.base_url
    opt[:importer]   ||= :ia_bulk
    s, f = bulk_upload_edit(event_args, **opt)
    self.succeeded = s
    self.failures.concat(f)
  end

  # For bulk-edit, this action is a "no-op" because indexing will have been
  # done per-batch in #wf_validate_submission.
  #
  # @param [Array] _event_args        Ignored.
  #
  # @return [void]
  #
  def wf_index_update(*_event_args)
    __debug_items(binding)
    if succeeded.blank?
      self.failures << "#{__method__}: NO ENTRIES - INTERNAL WORKFLOW ERROR"
    elsif DEFER_INDEXING
      s, f, _ = bulk_update_in_index(*succeeded)
      self.succeeded = s
      self.failures.concat(f)
    end
  end

end

module UploadWorkflow::Bulk::Edit::Simulation
  include UploadWorkflow::Bulk::Simulation
end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Bulk::Edit::Events
  include UploadWorkflow::Bulk::Events
  include UploadWorkflow::Bulk::Edit::Simulation
end

# Overridden state transition methods specific to bulk update.
#
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

    __debug_sim('USER must `cancel!` or `submit!` to advance...')

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
      wf_set_records_state
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
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :edit,      transitions_to: :editing,     **IF_SUBMITTER
    end

    # =========================================================================
    # = Bulk update (en.emma.upload.state_group.edit)
    # =========================================================================

    state :editing do
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :submit,    transitions_to: :modifying,   **IF_SUBMITTER
    end

    state :modifying do
      event :reject,    transitions_to: :failed
      event :advance,   transitions_to: :modified
    end

    state :modified do
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
