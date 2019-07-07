class CreateArtifacts < ActiveRecord::Migration[5.2]
  def change
    create_table :artifacts do |t|
      t.string :format
      t.belongs_to :title, foreign_key: true
      t.belongs_to :edition, foreign_key: true

      t.timestamps
    end
  end
end
