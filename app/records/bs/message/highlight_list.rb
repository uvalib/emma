# app/records/bs/message/highlight_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::HighlightList
#
# @attr [Array<BsAllowsType>]          allows
# @attr [Array<Bs::Record::Highlight>] highlights
# @attr [Integer]                      limit
# @attr [Array<Bs::Record::Link>]      links
# @attr [String]                       next
#
# @see https://apidocs.bookshare.org/reference/index.html#_highlight_list
#
class Bs::Message::HighlightList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::Highlight

  schema do
    has_many  :allows,      BsAllowsType
    has_many  :highlights,  LIST_ELEMENT
    has_one   :limit,       Integer
    has_many  :links,       Bs::Record::Link
    has_one   :next
  end

end

__loading_end(__FILE__)
