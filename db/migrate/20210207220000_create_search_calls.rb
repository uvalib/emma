# db/migrate/*_create_search_calls.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateSearchCalls < ActiveRecord::Migration[6.0]

  def change

    create_table(:search_calls) do |t|
      t.json       :query
      t.json       :filter
      t.json       :sort
      t.json       :page
      t.json       :result
      t.belongs_to :user #, foreign_key: true
      t.datetime   :created_at
    end

  end

end
