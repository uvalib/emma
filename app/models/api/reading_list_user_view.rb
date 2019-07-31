# app/models/api/reading_list_user_view.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/link_methods'
require_relative 'common/reading_list_methods'
require_relative 'reading_list_subscription'

# Api::ReadingListUserView
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_reading_list_user_view
#
# NOTE: This duplicates:
# @see ApiReadingListUserView
#
# noinspection DuplicatedCode
class Api::ReadingListUserView < Api::Record::Base

  include Api::Common::LinkMethods
  include Api::Common::ReadingListMethods

  schema do
    attribute :access,        Access
    has_many  :allows,        AllowsType
    attribute :assignedBy,    String
    attribute :dateUpdated,   String
    attribute :description,   String, default: DEF_READING_LIST_DESCRIPTION
    has_many  :links,         Api::Link
    attribute :memberCount,   Integer
    attribute :name,          String
    attribute :owner,         String
    attribute :readingListId, String
    has_one   :subscription,  Api::ReadingListSubscription
    attribute :titleCount,    Integer
  end

end

__loading_end(__FILE__)
