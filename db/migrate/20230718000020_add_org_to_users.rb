# db/migrate/*_add_org_to_users.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddOrgToUsers < ActiveRecord::Migration[7.0]

  def change
    add_reference :users, :org
  end

end
