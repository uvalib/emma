# db/migrate/*_add_jobs_finished_at_to_good_job_batches.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddJobsFinishedAtToGoodJobBatches < ActiveRecord::Migration[7.2]

  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.column_exists?(:good_job_batches, :jobs_finished_at)
      end
    end

    change_table :good_job_batches do |t|
      t.datetime :jobs_finished_at
    end
  end

end
