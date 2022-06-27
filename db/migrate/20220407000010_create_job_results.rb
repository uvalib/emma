# db/migrate/*_create_job_results.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateJobResults < ActiveRecord::Migration[6.1]

  # noinspection RubyResolve
  def change
    create_table :job_results do |t|
      t.belongs_to :active_job, class_name: 'GoodJob::Job', type: :uuid
      t.jsonb      :output
      t.jsonb      :error
      t.jsonb      :diagnostic
      t.timestamps
    end
  end

end
