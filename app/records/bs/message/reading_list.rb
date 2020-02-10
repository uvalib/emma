# app/records/bs/message/reading_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ReadingList
#
# @attr [Access]                  access
# @attr [Array<AllowsType>]       allows
# @attr [String]                  assignedBy
# @attr [IsoDate]                 dateUpdated
# @attr [String]                  description
# @attr [Array<Bs::Record::Link>] links
# @attr [Integer]                 memberCount
# @attr [String]                  name
# @attr [String]                  owner
# @attr [String]                  readingListId
# @attr [Integer]                 subscriberCount
# @attr [Integer]                 titleCount
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list
#
class Bs::Message::ReadingList < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::ReadingListMethods

  schema do
    attribute :access,          Access
    has_many  :allows,          AllowsType
    attribute :assignedBy,      String
    attribute :dateUpdated,     IsoDate
    attribute :description,     String, default: DEF_READING_LIST_DESCRIPTION
    has_many  :links,           Bs::Record::Link
    attribute :memberCount,     Integer
    attribute :name,            String
    attribute :owner,           String
    attribute :readingListId,   String
    attribute :subscriberCount, Integer
    attribute :titleCount,      Integer
  end

end

__loading_end(__FILE__)