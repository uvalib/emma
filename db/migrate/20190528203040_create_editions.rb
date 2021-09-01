# db/migrate/*_create_periodicals.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateEditions < ActiveRecord::Migration[6.0]

  def change

    create_table(:editions) do |t|
      t.string :editionId
      t.timestamps
      t.belongs_to :periodical
    end

    create_join_table(:artifacts, :editions) do |t|
      t.index %i[artifact_id edition_id]
    end

  end

end
