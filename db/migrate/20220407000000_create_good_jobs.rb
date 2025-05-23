# db/migrate/*_create_good_jobs.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateGoodJobs < ActiveRecord::Migration[6.1]

  def change

    enable_extension 'pgcrypto'

    create_table(:good_jobs, id: :uuid) do |t|
      t.text      :queue_name
      t.integer   :priority
      t.jsonb     :serialized_params
      t.timestamp :scheduled_at
      t.timestamp :performed_at
      t.timestamp :finished_at
      t.text      :error
      t.timestamps
      t.uuid      :active_job_id
      t.text      :concurrency_key
      t.text      :cron_key
      t.uuid      :retried_good_job_id
      t.timestamp :cron_at
    end

    create_table(:good_job_processes, id: :uuid) do |t|
      t.timestamps
      t.jsonb :state
    end

    add_index :good_jobs, :scheduled_at,                name: :index_good_jobs_on_scheduled_at,                     where: '(finished_at IS NULL)'
    add_index :good_jobs, %i[queue_name scheduled_at],  name: :index_good_jobs_on_queue_name_and_scheduled_at,      where: '(finished_at IS NULL)'
    add_index :good_jobs, %i[active_job_id created_at], name: :index_good_jobs_on_active_job_id_and_created_at
    add_index :good_jobs, :concurrency_key,             name: :index_good_jobs_on_concurrency_key_when_unfinished,  where: '(finished_at IS NULL)'
    add_index :good_jobs, %i[cron_key created_at],      name: :index_good_jobs_on_cron_key_and_created_at
    add_index :good_jobs, %i[cron_key cron_at],         name: :index_good_jobs_on_cron_key_and_cron_at,             unique: true
    add_index :good_jobs, %i[active_job_id],            name: :index_good_jobs_on_active_job_id
    add_index :good_jobs, %i[finished_at],              name: :index_good_jobs_jobs_on_finished_at,                 where: 'retried_good_job_id IS NULL AND finished_at IS NOT NULL'

  end

end
