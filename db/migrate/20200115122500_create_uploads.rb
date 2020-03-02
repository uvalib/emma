# db/migrate/*_create_uploads.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateUploads < ActiveRecord::Migration[6.0]

  def change

    create_table(:uploads) do |t|
      t.text       :file_data
      t.text       :emma_data
      t.belongs_to :user
      t.string     :repository
      t.string     :repository_id
      t.string     :fmt
      t.string     :ext
      t.string     :state
      t.timestamps
    end

  end

end
