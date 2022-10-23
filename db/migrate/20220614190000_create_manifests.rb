# db/migrate/*_create_manifests.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateManifests < ActiveRecord::Migration[6.1]

  def change

    enable_extension 'pgcrypto'

    create_table(:manifests, id: :uuid) do |t|
      t.string     :name
      t.belongs_to :user
      t.timestamps
    end

  end

end
