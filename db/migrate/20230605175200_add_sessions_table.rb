# db/migrate/*_add_sessions_table.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddSessionsTable < ActiveRecord::Migration[7.0]

  def change
    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end

    add_index :sessions, :session_id, :unique => true
    add_index :sessions, :updated_at
  end

end
