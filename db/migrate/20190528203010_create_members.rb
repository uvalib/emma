class CreateMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :members do |t|
      t.string :emailAddress
      t.boolean :institutional
      t.belongs_to :user, foreign_key: true

      t.timestamps
    end
  end
end
