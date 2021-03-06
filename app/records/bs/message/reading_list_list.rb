# app/records/bs/message/reading_list_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ReadingListList
#
# @attr [Array<BsAllowsType>]                    allows
# @attr [Integer]                                limit
# @attr [Array<Bs::Record::Link>]                links
# @attr [Array<Bs::Record::ReadingListUserView>] lists
# @attr [String]                                 next
# @attr [Integer]                                totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_list
#
class Bs::Message::ReadingListList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,        BsAllowsType
    has_one   :limit,         Integer
    has_many  :links,         Bs::Record::Link
    has_many  :lists,         Bs::Record::ReadingListUserView
    has_one   :next
    has_one   :totalResults,  Integer
  end

end

__loading_end(__FILE__)
