# db/migrate/*_create_enrollments.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateEnrollments < ActiveRecord::Migration[7.1]

  def change

    create_table :enrollments do |t|
      t.string    :short_name
      t.string    :long_name
      t.string    :ip_domain,     array: true
     #t.string    :provider                     # NOTE: not copied from Org
     #t.bigint    :contact,       array: true   # NOTE: not copied from Org
     #t.datetime  :start_date                   # NOTE: not copied from Org
     #t.string    :status                       # NOTE: not copied from Org
     #t.datetime  :status_date                  # NOTE: not copied from Org
     #t.json      :info,          default: nil  # NOTE: not copied from Org
     #t.json      :history,       default: nil  # NOTE: not copied from Org
      t.json      :org_users                    # JSON array of User field values
      t.text      :request_notes, default: nil  # Additional user comments
      t.text      :admin_notes,   default: nil  # Administrator comments
      t.timestamps
    end

    add_index(:enrollments, :short_name)
    add_index(:enrollments, :long_name)

  end

end
