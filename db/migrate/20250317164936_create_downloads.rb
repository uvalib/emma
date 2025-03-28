# db/migrate/*_create_downloads.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateDownloads < ActiveRecord::Migration[8.0]

  def change
    create_table :downloads do |t|
      t.belongs_to :user
      t.string :source
      t.string :record
      t.string :fmt
      t.string :publisher
      t.string :link

      t.timestamps
    end
  end

end
