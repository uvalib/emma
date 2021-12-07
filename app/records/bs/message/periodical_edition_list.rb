# app/records/bs/message/periodical_edition_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::PeriodicalEditionList
#
# @attr [Array<BsAllowsType>]                  allows
# @attr [Integer]                              limit
# @attr [Array<Bs::Record::Link>]              links
# @attr [Bs::Record::StatusModel]              message
# @attr [String]                               next
# @attr [Array<Bs::Record::PeriodicalEdition>] periodicalEditions
# @attr [Integer]                              totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_periodical_edition_list
#
class Bs::Message::PeriodicalEditionList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::PeriodicalEdition

  schema do
    has_many  :allows,             BsAllowsType
    has_one   :limit,              Integer
    has_many  :links,              Bs::Record::Link
    has_one   :message,            Bs::Record::StatusModel
    has_one   :next
    has_many  :periodicalEditions, LIST_ELEMENT
    has_one   :totalResults,       Integer
  end

end

__loading_end(__FILE__)
