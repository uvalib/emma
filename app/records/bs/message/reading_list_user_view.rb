# app/records/bs/message/reading_list_user_view.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ReadingListUserView
#
# @attr [BsAccess]                            access
# @attr [Array<BsAllowsType>]                 allows
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
# @see Bs::Record::ReadingListUserView (duplicate schema)
#
class Bs::Message::ReadingListUserView < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::ReadingListMethods

  schema do
    has_one   :access,        BsAccess
    has_many  :allows,        BsAllowsType
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
