# app/models/api_reading_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'

# ApiReadingList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list
#
class ApiReadingList < Api::Message

  schema do
    attribute :access,          Access
    has_many  :allows,          String
    attribute :assignedBy,      String
    attribute :dateUpdated,     String
    attribute :description,     String
    has_many  :links,           Link
    attribute :memberCount,     Integer
    attribute :name,            String
    attribute :owner,           String
    attribute :readingListId,   String
    attribute :subscriberCount, Integer
    attribute :titleCount,      Integer
  end

end

__loading_end(__FILE__)
