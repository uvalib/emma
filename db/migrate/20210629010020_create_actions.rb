# db/migrate/*_create_actions.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateActions < ActiveRecord::Migration[6.1]

  def change

    create_table(:actions) do |t|
      t.belongs_to :phase
      t.belongs_to :user
      t.string     :command
      t.string     :type
      t.string     :state
      t.string     :condition
      t.string     :action
      t.text       :report
      t.integer    :retries, default: 0
      t.json       :emma_data
      t.json       :file_data
      t.string     :file_source
      t.integer    :checksum
      t.timestamps
    end

  end

end
