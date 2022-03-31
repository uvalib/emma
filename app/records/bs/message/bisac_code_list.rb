# app/records/bs/message/bisac_code_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::BisacCodeList
#
# @attr [Array<Bs::Record::BisacCode>] bisacCodes
# @attr [Integer]                      limit
# @attr [String]                       next
# @attr [Integer]                      totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_bisac_code_list
#
class Bs::Message::BisacCodeList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::BisacCode

  schema do
    has_many  :bisacCodes,   LIST_ELEMENT
    has_one   :limit,        Integer
    has_one   :next
    has_one   :totalResults, Integer
  end

end

__loading_end(__FILE__)
