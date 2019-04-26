# app/models/api_reading_list_titles_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/reading_list_title'

# ApiReadingListTitlesList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list_titles_list
#
class ApiReadingListTitlesList < Api::Message

  schema do
    has_many  :allows,        String
    attribute :limit,         Integer
    has_many  :links,         Link
    attribute :next,          String
    attribute :readingListId, String
    has_many  :titles,        ReadingListTitle
    attribute :totalResults,  Integer
  end

end

__loading_end(__FILE__)
