class CreateEditions < ActiveRecord::Migration[5.2]
  def change
    create_table :editions do |t|
      t.string :editionId
      t.belongs_to :reading_list, foreign_key: true

      t.timestamps
    end
  end
end
