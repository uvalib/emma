# db/migrate/*_create_orgs.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateOrgs < ActiveRecord::Migration[7.0]

  def change

    create_table :orgs do |t|
      t.string    :short_name
      t.string    :long_name
      t.string    :ip_domain, array: true
      t.string    :provider
      t.bigint    :contact,   array: true
      t.datetime  :start_date
      t.string    :status
      t.datetime  :status_date
      t.json      :info,      default: nil
      t.json      :history,   default: nil
      t.timestamps
    end

    add_index(:orgs, :short_name)
    add_index(:orgs, :long_name)

  end

end
