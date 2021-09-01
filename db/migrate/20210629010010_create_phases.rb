# db/migrate/*_create_phases.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreatePhases < ActiveRecord::Migration[6.1]

  def change

    create_table(:phases) do |t|
      t.belongs_to :entry
      t.belongs_to :user
      t.references :bulk, foreign_key: { to_table: :phases }
      t.string     :command
      t.string     :type
      t.string     :state
      t.text       :remarks
      t.string     :submission_id
      t.string     :repository
      t.string     :fmt
      t.string     :ext
      t.json       :emma_data
      t.json       :file_data
      t.timestamps
    end

    add_index :phases, %i[entry_id type]

  end

end
