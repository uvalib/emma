# db/migrate/*_add_references_to_users.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddReferencesToUsers < ActiveRecord::Migration[6.1]

  def change
    add_reference :users, :effective, to_table: :users
  end

end
