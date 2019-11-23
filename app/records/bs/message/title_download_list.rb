# app/records/bs/message/title_download_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::TitleDownloadList
#
# @attr [Array<AllowsType>]                allows
# @attr [Array<Bs::Record::Link>]          links
# @attr [String]                           next
# @attr [Array<Bs::Record::TitleDownload>] titleDownloads
# @attr [Integer]                          totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_download_list
#
class Bs::Message::TitleDownloadList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,         AllowsType
    has_many  :links,          Bs::Record::Link
    attribute :next,           String
    has_many  :titleDownloads, Bs::Record::TitleDownload
    attribute :totalResults,   Integer
  end

end

__loading_end(__FILE__)
