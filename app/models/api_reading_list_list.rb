# app/models/api_reading_list_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/reading_list_user_view'

# ApiReadingListList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list_list
#
class ApiReadingListList < Api::Message

  schema do
    has_many  :allows,        String
    attribute :limit,         Integer
    has_many  :links,         Link
    has_many  :lists,         ReadingListUserView
    attribute :next,          String
    attribute :totalResults,  Integer
  end

end

__loading_end(__FILE__)
