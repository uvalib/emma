# app/models/api_title_download_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiTitleDownloadList
#
# @attr [Array<AllowsType>]         allows
# @attr [Array<Api::Link>]          links
# @attr [String]                    next
# @attr [Array<Api::TitleDownload>] titleDownloads
# @attr [Integer]                   totalResults
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_download_list
#
class ApiTitleDownloadList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,         AllowsType
    has_many  :links,          Api::Link
    attribute :next,           String
    has_many  :titleDownloads, Api::TitleDownload
    attribute :totalResults,   Integer
  end

end

__loading_end(__FILE__)
