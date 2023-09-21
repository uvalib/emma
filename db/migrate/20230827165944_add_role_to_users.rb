# db/migrate/*_add_role_to_users.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddRoleToUsers < ActiveRecord::Migration[7.0]

  def change
    add_column :users, :role, :string
  end

end
