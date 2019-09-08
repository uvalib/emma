# db/migrate/*_create_artifacts.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateArtifacts < ActiveRecord::Migration[6.0]

  def change
    create_table(:artifacts) do |t|
      t.string :format
      t.timestamps
      t.belongs_to :entry, polymorphic: true # Either 'title' or 'edition'.
    end
  end

end
