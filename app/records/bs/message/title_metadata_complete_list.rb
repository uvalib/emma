# app/records/bs/message/title_metadata_complete_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::TitleMetadataCompleteList
#
# @attr [Array<BsAllowsType>]                      allows
# @attr [Integer]                                  limit
# @attr [Array<Bs::Record::Link>]                  links
# @attr [String]                                   next
# @attr [Array<Bs::Record::TitleMetadataComplete>] titles
# @attr [Integer]                                  totalResults
#
# @see https://apidocs.bookshare.org/catalog/index.html#_title_metadata_complete_list
#
class Bs::Message::TitleMetadataCompleteList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many  :allows,       BsAllowsType
    has_one   :limit,        Integer
    has_many  :links,        Bs::Record::Link
    has_one   :next
    has_many  :titles,       Bs::Record::TitleMetadataComplete
    has_one   :totalResults, Integer
  end

end

__loading_end(__FILE__)
