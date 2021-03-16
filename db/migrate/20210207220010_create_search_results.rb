# db/migrate/*_create_search_results.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateSearchResults < ActiveRecord::Migration[6.0]

  def change

    create_table(:search_results) do |t|
      t.string  :title
      t.string  :description
      t.string  :format
      t.string  :formatVersion
      t.string  :identifier
      t.string  :repository
      t.string  :repositoryRecordId
    end

    create_join_table(:search_calls, :search_results) do |t|
      t.index %i[search_call_id search_result_id], name: 'index_searches_on_call_id_and_result_id'
    end

  end

end
