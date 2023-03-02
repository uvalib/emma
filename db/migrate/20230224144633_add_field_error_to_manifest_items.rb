# db/migrate/*_add_field_error_to_manifest_items.rb
#
# frozen_string_literal: true
# warn_indent:           true

class AddFieldErrorToManifestItems < ActiveRecord::Migration[7.0]

  def change
    add_column :manifest_items, :field_error, :jsonb
  end

end
