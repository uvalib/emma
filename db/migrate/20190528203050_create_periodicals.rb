# db/migrate/*_create_periodicals.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreatePeriodicals < ActiveRecord::Migration[6.0]

  def change

    create_table(:periodicals) do |t|
      t.string :seriesId
      t.timestamps
    end

    create_join_table(:editions, :periodicals) do |t|
      t.index %i[edition_id periodical_id]
    end

  end

end
