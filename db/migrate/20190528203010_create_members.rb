# db/migrate/*_create_members.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateMembers < ActiveRecord::Migration[6.0]

  def change
    create_table(:members) do |t|
      t.string  :emailAddress
      t.boolean :institutional
      t.timestamps
      t.belongs_to :user
    end
  end

end
