# db/migrate/*_create_reading_lists.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateReadingLists < ActiveRecord::Migration[6.0]

  def change

    create_table(:reading_lists) do |t|
      t.string :readingListId
      t.timestamps
      t.belongs_to :user
    end

    create_join_table(:members, :reading_lists) do |t|
      t.index %i[member_id reading_list_id]
    end

    create_join_table(:editions, :reading_lists) do |t|
      t.index %i[edition_id reading_list_id]
    end

    create_join_table(:reading_lists, :titles) do |t|
      t.index %i[reading_list_id title_id]
    end

  end

end
