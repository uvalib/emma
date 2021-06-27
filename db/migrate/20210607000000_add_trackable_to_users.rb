# db/migrate/*_add_trackable_to_users.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddTrackableToUsers < ActiveRecord::Migration[6.1]

  def change
    add_column :users, :sign_in_count,      :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at,    :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip,    :string
  end

end
