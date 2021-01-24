# app/records/bs/record/reading_list_user_view.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ReadingListUserView
#
# @attr [Access]                              access
# @attr [Array<AllowsType>]                   allows
# @attr [String]                              assignedBy
# @attr [IsoDate]                             dateUpdated
# @attr [String]                              description
# @attr [Array<Bs::Record::Link>]             links
# @attr [Integer]                             memberCount
# @attr [String]                              name
# @attr [String]                              owner
# @attr [String]                              readingListId
# @attr [Bs::Record::ReadingListSubscription] subscription
# @attr [Integer]                             titleCount
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_user_view
#
# @note This duplicates Bs::Message::ReadingListUserView
#
#--
# noinspection DuplicatedCode
#++
class Bs::Record::ReadingListUserView < Bs::Api::Record

  include Bs::Shared::LinkMethods
  include Bs::Shared::ReadingListMethods

  schema do
    has_one   :access,        Access
    has_many  :allows,        AllowsType
    has_one   :assignedBy
    has_one   :dateUpdated,   IsoDate
    has_one   :description,   default: DEF_READING_LIST_DESCRIPTION
    has_many  :links,         Bs::Record::Link
    has_one   :memberCount,   Integer
    has_one   :name
    has_one   :owner
    has_one   :readingListId
    has_one   :subscription,  Bs::Record::ReadingListSubscription
    has_one   :titleCount,    Integer
  end

end

__loading_end(__FILE__)
