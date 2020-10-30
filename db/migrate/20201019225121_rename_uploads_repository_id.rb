# db/migrate/*_rename_uploads_repository_id.rb
#
# frozen_string_literal: true
# warn_indent:           true

class RenameUploadsRepositoryId < ActiveRecord::Migration[6.0]

  def change
    rename_column :uploads, :repository_id, :submission_id
  end

end
