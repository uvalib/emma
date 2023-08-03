# db/migrate/*_add_status_to_users.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddStatusToUsers < ActiveRecord::Migration[7.0]

  def change
    add_column :users, :preferred_email,  :string
    add_column :users, :phone,            :string
    add_column :users, :address,          :string
    add_column :users, :status,           :string
    add_column :users, :status_date,      :datetime
  end

end
