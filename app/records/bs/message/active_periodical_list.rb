# app/records/bs/message/active_periodical_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ActivePeriodicalList
#
# @attr [Array<Bs::Record::ActivePeriodical>] activeTitles
# @attr [Array<BsAllowsType>]                 allows
# @attr [Integer]                             limit
# @attr [Array<Bs::Record::Link>]             links
# @attr [Bs::Record::StatusModel]             message
# @attr [String]                              next
# @attr [Integer]                             totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_active_periodical_list
#
# @see Bs::Message::ActiveBookList (similar schema)
#
class Bs::Message::ActivePeriodicalList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :activeTitles, Bs::Record::ActivePeriodical
    has_many  :allows,       BsAllowsType
    has_one   :limit,        Integer
    has_many  :links,        Bs::Record::Link
    has_one   :message,      Bs::Record::StatusModel
    has_one   :next
    has_one   :totalResults, Integer
  end

end

__loading_end(__FILE__)
