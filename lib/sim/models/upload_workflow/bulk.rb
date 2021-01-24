# lib/sim/models/upload_workflow/bulk.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# These overrides are segregated from the normal code to make them easier to
# hide from Yard when generating documentation.

__loading_begin(__FILE__)

require_relative '../../../../app/models/upload_workflow/bulk'

# =============================================================================
# :section: Event handlers
# =============================================================================

public

module UploadWorkflow::Bulk::Events

  # ===========================================================================
  # :section: UploadWorkflow::Events overrides
  # ===========================================================================

  public

  # The user initiates submission of a new entry.
  def create(*)
    super.tap do
      __debug_sim('USER initiates submission of new entries.')
    end
  end

  # The user initiates modification of an existing entry.
  def edit(*)
    super.tap do
      __debug_sim('USER initiates modification of existing entries.')
    end
  end

  # The user initiates removal of an existing entry.
  def remove(*)
    super.tap do
      __debug_sim('USER initiates removal of existing entries.')
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
