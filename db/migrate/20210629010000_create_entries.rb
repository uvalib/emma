# db/migrate/*_create_entries.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateEntries < ActiveRecord::Migration[6.1]

  def change

    create_table(:entries) do |t|
      t.belongs_to :user
      t.string     :submission_id
      t.string     :repository
      t.string     :fmt
      t.string     :ext
      t.json       :emma_data
      t.json       :file_data
      t.timestamps
    end

  end

end
