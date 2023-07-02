# db/migrate/*_add_provider_to_users.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddProviderToUsers < ActiveRecord::Migration[7.0]

  def change
    add_column :users, :provider, :string
  end

end
