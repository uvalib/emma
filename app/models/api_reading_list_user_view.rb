# app/models/api_reading_list_user_view.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/reading_list_user_view'

# ApiReadingListUserView
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list_user_view
#
# NOTE: This duplicates:
# @see Api::ReadingListUserView
#
class ApiReadingListUserView < Api::Message

  schema do
    attribute :access,        Access
    has_many  :allows,        AllowsType
    attribute :assignedBy,    String
    attribute :dateUpdated,   String
    attribute :description,   String
    has_many  :links,         Api::Link
    attribute :memberCount,   Integer
    attribute :name,          String
    attribute :owner,         String
    attribute :readingListId, String
    has_one   :subscription,  Api::ReadingListSubscription
    attribute :titleCount,    Integer
  end

  include Api::Common::LinkMethods
  include Api::Common::ReadingListMethods

end

__loading_end(__FILE__)
