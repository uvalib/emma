# db/migrate/*_add_editor_to_uploads.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddEditorToUploads < ActiveRecord::Migration[6.0]

  def change
    add_column :uploads, :phase,          :string
    add_column :uploads, :edit_state,     :string
    add_column :uploads, :edit_user,      :string
    add_column :uploads, :edit_file_data, :text
    add_column :uploads, :edit_emma_data, :text
    add_column :uploads, :edited_at,      :timestamp
  end

end
