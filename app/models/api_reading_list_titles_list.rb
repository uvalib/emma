# app/models/api_reading_list_titles_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/link'
require_relative 'api/reading_list_title'
require_relative 'api/common/reading_list_methods'
require_relative 'api/common/sequence_methods'

# ApiReadingListTitlesList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list_titles_list
#
class ApiReadingListTitlesList < Api::Message

  schema do
    has_many  :allows,        AllowsType
    attribute :limit,         Integer
    has_many  :links,         Api::Link
    attribute :next,          String
    attribute :readingListId, String
    has_many  :titles,        Api::ReadingListTitle
    attribute :totalResults,  Integer
  end

  include Api::Common::SequenceMethods
  include Api::Common::ReadingListMethods

end

__loading_end(__FILE__)
