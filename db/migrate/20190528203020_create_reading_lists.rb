class CreateReadingLists < ActiveRecord::Migration[5.2]
  def change
    create_table :reading_lists do |t|
      t.string :readingListId

      t.timestamps
    end
  end
end
