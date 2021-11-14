# db/migrate/*_create_emma_statuses.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateEmmaStatuses < ActiveRecord::Migration[6.1]

  def change

    create_table(:emma_statuses) do |t|
      t.string  :item
      t.string  :value
      t.boolean :active
      t.timestamps
    end

  end

end
