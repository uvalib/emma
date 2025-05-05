# db/migrate/*_add_last_indexed_submission_id_to_manifest_items.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddLastIndexedSubmissionIdToManifestItems < ActiveRecord::Migration[7.0]

  def change
    add_column :manifest_items, :last_indexed,  :timestamp
    add_column :manifest_items, :submission_id, :string
  end

end
