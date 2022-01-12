# app/models/upload_workflow/bulk/create.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class UploadWorkflow::Bulk::Create < UploadWorkflow::Bulk
  include UploadWorkflow::Create
end

# =============================================================================
# :section: Auxiliary
# =============================================================================

public

module UploadWorkflow::Bulk::Create::Errors
  include UploadWorkflow::Bulk::Errors
end

module UploadWorkflow::Bulk::Create::Properties
  include UploadWorkflow::Bulk::Properties
  include UploadWorkflow::Bulk::Create::Errors
end

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Bulk::Create::External
  include UploadWorkflow::Bulk::External
  include UploadWorkflow::Bulk::Create::Properties
  include UploadWorkflow::Bulk::Create::Events
end

module UploadWorkflow::Bulk::Create::Data
  include UploadWorkflow::Bulk::Data
  include UploadWorkflow::Bulk::Create::External
end

# New and overridden action methods specific to bulk submission.
#
module UploadWorkflow::Bulk::Create::Actions

  include UploadWorkflow::Bulk::Actions
  include UploadWorkflow::Bulk::Create::Data

  # This should be *false* in order to get the full benefit of batch operation.
  #
  # If this is *true* then it essentially defeats batching by segregating
  # creation activities (download, upload, database) into one phase, and
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

  # This action basically runs the bulk upload to completion.
  #
  # Since there are no review workflow steps, and indexing has to be done for
  # each batch in order to support the notion of batching, then the bulk-upload
  # workflow is "validated" by completing it and reporting on the
  # successes/failures of the overall process.
  #
  # @param [Array] event_args
  #
  # @return [void]
  #
  # @see UploadWorkflow::Bulk::External#bulk_upload_create
  #
  def wf_validate_submission(*event_args)
    __debug_items(binding)
    opt = event_args.extract_options!.dup
    opt[:index]        = false if DEFER_INDEXING && !opt.key?(:index)
    opt[:user]       ||= current_user
    opt[:base_url]   ||= nil #request.base_url
    opt[:importer]   ||= :ia_bulk
    opt[:repository] ||= EmmaRepository.default
    s, f = bulk_upload_create(event_args, **opt)
    self.succeeded = s
    self.failures += f
  end

  # For bulk-upload, this action is a "no-op" because indexing will have been
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
      s, f, _ = bulk_add_to_index(*succeeded)
      self.succeeded = s
      self.failures += f
    end
  end

end

module UploadWorkflow::Bulk::Create::Simulation
  include UploadWorkflow::Bulk::Simulation
end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Bulk::Create::Events
  include UploadWorkflow::Bulk::Events
  include UploadWorkflow::Bulk::Create::Simulation
end

# Overridden state transition methods specific to bulk submission.
#
module UploadWorkflow::Bulk::Create::States

  include UploadWorkflow::Bulk::States
  include UploadWorkflow::Bulk::Create::Events
  include UploadWorkflow::Bulk::Create::Actions

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

    __debug_sim('System presents a form to select control file.')

    unless simulating
      wf_start_submission(*event_args)
    end

    __debug_sim('USER must `cancel!` or `submit!` to advance...')

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
      # From UploadController#bulk_create:
      # succeeded, failed = bulk_upload_create(data, base_url: url, user: @user)
      __debug_sim('CODE') do
        args = "data=#{submission.data.inspect}"
        opt  = 'base_url: url, user: @user'
        "succeeded, failed = bulk_upload_create(#{args}, #{opt})"
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
      wf_set_records_state
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
      reject!  # NOTE: => :failed
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
    advance! # NOTE: => :staging
    self
  end

end

# =============================================================================
# :section:
# =============================================================================

public

# Bulk submission workflow.
#
class UploadWorkflow::Bulk::Create < UploadWorkflow::Bulk

  include UploadWorkflow::Bulk::Create::Events
  include UploadWorkflow::Bulk::Create::States
  include UploadWorkflow::Bulk::Create::Transitions

  workflow do

    state :starting do
      event :start,     transitions_to: :starting,    **IF_SYS_DEBUG
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :create,    transitions_to: :creating,    **IF_SUBMITTER
    end

    # =========================================================================
    # = Bulk upload (en.emma.upload.state_group.create)
    # =========================================================================

    state :creating do
      event :cancel,    transitions_to: :canceled,    **IF_SUBMITTER
      event :submit,    transitions_to: :submitting,  **IF_SUBMITTER
    end

    state :submitting do
      event :reject,    transitions_to: :failed
      event :advance,   transitions_to: :submitted
    end

    state :submitted do
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
