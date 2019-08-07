# app/models/api_reading_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/common/reading_list_methods'

# ApiReadingList
#
# @attr [Access]            access
# @attr [Array<AllowsType>] allows
# @attr [String]            assignedBy
# @attr [String]            dateUpdated
# @attr [String]            description
# @attr [Array<Api::Link>]  links
# @attr [Integer]           memberCount
# @attr [String]            name
# @attr [String]            owner
# @attr [String]            readingListId
# @attr [Integer]           subscriberCount
# @attr [Integer]           titleCount
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list
#
class ApiReadingList < Api::Message

  include Api::Common::LinkMethods
  include Api::Common::ReadingListMethods

  schema do
    attribute :access,          Access
    has_many  :allows,          AllowsType
    attribute :assignedBy,      String
    attribute :dateUpdated,     String
    attribute :description,     String, default: DEF_READING_LIST_DESCRIPTION
    has_many  :links,           Api::Link
    attribute :memberCount,     Integer
    attribute :name,            String
    attribute :owner,           String
    attribute :readingListId,   String
    attribute :subscriberCount, Integer
    attribute :titleCount,      Integer
  end

end

__loading_end(__FILE__)
