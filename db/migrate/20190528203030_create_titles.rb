# db/migrate/*_create_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateTitles < ActiveRecord::Migration[6.0]

  def change

    create_table(:titles) do |t|
      t.string :bookshareId
      t.timestamps
    end

    create_join_table(:artifacts, :titles) do |t|
      t.index %i[artifact_id title_id]
    end

  end

end
