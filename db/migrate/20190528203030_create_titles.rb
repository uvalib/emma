class CreateTitles < ActiveRecord::Migration[5.2]
  def change
    create_table :titles do |t|
      t.string :bookshareId
      t.belongs_to :reading_list, foreign_key: true

      t.timestamps
    end
  end
end
