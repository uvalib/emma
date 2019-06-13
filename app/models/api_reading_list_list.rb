# app/models/api_reading_list_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/link'
require_relative 'api/reading_list_user_view'
require_relative 'api/common/sequence_methods'

# ApiReadingListList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list_list
#
class ApiReadingListList < Api::Message

  schema do
    has_many  :allows,        AllowsType
    attribute :limit,         Integer
    has_many  :links,         Api::Link
    has_many  :lists,         Api::ReadingListUserView
    attribute :next,          String
    attribute :totalResults,  Integer
  end

  include Api::Common::SequenceMethods

end

__loading_end(__FILE__)
