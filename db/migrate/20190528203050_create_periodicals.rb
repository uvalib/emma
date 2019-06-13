class CreatePeriodicals < ActiveRecord::Migration[5.2]
  def change
    create_table :periodicals do |t|
      t.string :seriesId
      t.belongs_to :reading_list, foreign_key: true

      t.timestamps
    end
  end
end
