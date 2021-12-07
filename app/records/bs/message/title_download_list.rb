# app/records/bs/message/title_download_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::TitleDownloadList
#
# @attr [Array<BsAllowsType>]              allows
# @attr [Array<Bs::Record::Link>]          links
# @attr [String]                           next
# @attr [Array<Bs::Record::TitleDownload>] titleDownloads
# @attr [Integer]                          totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_download_list
#
class Bs::Message::TitleDownloadList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::TitleDownload

  schema do
    has_many  :allows,         BsAllowsType
    has_many  :links,          Bs::Record::Link
    has_one   :next
    has_many  :titleDownloads, LIST_ELEMENT
    has_one   :totalResults,   Integer
  end

end

__loading_end(__FILE__)
