# db/migrate/*_add_index_good_jobs_concurrency_key_created_at.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddIndexGoodJobsConcurrencyKeyCreatedAt < ActiveRecord::Migration[8.0]

  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.index_exists? :good_jobs, [:concurrency_key, :created_at]
      end
    end

    add_index :good_jobs, [:concurrency_key, :created_at], algorithm: :concurrently
  end

end
