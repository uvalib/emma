# lib/sim/models/upload_workflow.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# These overrides are segregated from the normal code to make them easier to
# hide from Yard when generating documentation.

__loading_begin(__FILE__)

require_relative '../../../app/models/upload_workflow'

# =============================================================================
# :section: Core
# =============================================================================

public

module UploadWorkflow::Simulation

  include UploadWorkflow::Data

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Properties used to drive simulated behavior.
  #
  # @type [Hash{Symbol=>Boolean,Integer}]
  #
  PROPERTY = {

    invalid_file:         false,  # on_validating_entry
    invalid_entry:        false,  # on_submitting_entry
    db_failure:           false,  # on_submitting_entry
    no_review:            false,  # on_submitted_entry

    edit_invalid_file:    false,  # on_replacing_entry
    edit_invalid_entry:   false,  # on_modifying_entry
    edit_db_failure:      false,  # on_modifying_entry
    edit_no_review:       false,  # on_modified_entry

    auto_remove_submit:   false,  # on_removing_entry
    auto_remove_cancel:   false,  # on_removing_entry
    remove_emma_items:    true,   # on_removed_entry

    auto_review:          false,  # on_scheduling_entry
    no_reviewers:         false,  # on_assigning_entry

    reviewer_checks:      3,      # on_holding_entry
    reviewer_found:       true,   # on_holding_entry
    reviewer_abort:       true,   # on_holding_entry

    auto_approve:         false,  # on_reviewing_entry
    auto_reject:          false,  # on_reviewing_entry

    upsert_emma_items:    false,  # on_staging_entry

    retrieval_checks:     3,      # on_unretrieved_entry
    submission_retrieved: true,   # on_unretrieved_entry
    retrieval_abort:      true,   # on_unretrieved_entry

    indexed_item_checks:  3,      # on_indexing_entry
    indexed_item_found:   true,   # on_indexing_entry
    indexed_item_abort:   true,   # on_indexing_entry

  }.freeze

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  class ReviewerTask < SimulatedTask
    # noinspection RubyMismatchedArgumentType
    def initialize(started: false)
      super(
        result:  PROPERTY[:reviewer_found],
        reps:    PROPERTY[:reviewer_checks],
        restart: !PROPERTY[:reviewer_abort],
        started: started
      )
    end
  end

  class RetrievalTask < SimulatedTask
    # noinspection RubyMismatchedArgumentType
    def initialize(started: false)
      super(
        result:  PROPERTY[:submission_retrieved],
        reps:    PROPERTY[:retrieval_checks],
        restart: !PROPERTY[:retrieval_abort],
        started: started
      )
    end
  end

  class IndexTask < SimulatedTask
    # noinspection RubyMismatchedArgumentType
    def initialize(started: false)
      super(
        name:    'index check',
        result:  PROPERTY[:indexed_item_found],
        reps:    PROPERTY[:indexed_item_checks],
        restart: !PROPERTY[:indexed_item_abort],
        started: started
      )
    end
  end

end

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Events

  # ===========================================================================
  # :section: Workflow::Base overrides - Events
  # ===========================================================================

  public

  # The user initiates submission of a new entry.
  def create(*)
    super.tap do
      __debug_sim('USER initiates submission of a new entry.')
    end
  end

  # The user initiates modification of an existing entry.
  def edit(*)
    super.tap do
      if new_submission?
        __debug_sim('USER has decided to modify the submission.')
      else
        __debug_sim('USER initiates modification of an existing entry.')
      end
    end
  end

  # The user initiates removal of an existing entry.
  def remove(*)
    super.tap do
      __debug_sim('USER initiates removal of an existing entry or entries.')
    end
  end

  # The user chooses to cancel the submission process.
  def cancel(*)
    super.tap do
      __debug_sim('USER has decided to withdraw the submission.')
    end
  end

  # The reviewer (or the system) indicates that the submission requires
  # change(s).
  def reject(*)
    super.tap do
      __debug_sim('USER must make change(s) to complete the submission.')
    end
  end

  # The reviewer initiates review of the submission.
  def review(*)
    super.tap do
      __debug_sim('REVIEWER initiates review of the submission.')
    end
  end

  # The system is resetting the workflow state.
  def reset(*)
    super.tap do
      __debug_sim('*** RESET WORKFLOW STATE ***')
    end
  end

  # The system is returning to the previous workflow state.
  def resume(*)
    super.tap do
      __debug_sim("*** RESUME WORKFLOW STATE #{prev_state} ***")
    end
  end

end

__loading_end(__FILE__)
