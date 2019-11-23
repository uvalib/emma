# app/records/bs/message/active_book_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ActiveBookList
#
# @attr [Array<Bs::Record::ActiveBook>] activeTitles
# @attr [Array<AllowsType>]             allows
# @attr [Integer]                       limit
# @attr [Array<Bs::Record::Link>]       links
# @attr [Bs::Record::StatusModel]       message
# @attr [String]                        next
# @attr [Integer]                       totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_book_list
#
# NOTE: This duplicates the form of:
# @see Bs::Message::ActivePeriodicalList
#
class Bs::Message::ActiveBookList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :activeTitles, Bs::Record::ActiveBook
    has_many  :allows,       AllowsType
    attribute :limit,        Integer
    has_many  :links,        Bs::Record::Link
    has_one   :message,      Bs::Record::StatusModel
    attribute :next,         String
    attribute :totalResults, Integer
  end

end

__loading_end(__FILE__)
