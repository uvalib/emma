# app/models/api_title_download_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/title_download'

# ApiTitleDownloadList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_download_list
#
class ApiTitleDownloadList < Api::Message

  schema do
    has_many  :allows,         String
    has_many  :links,          Link
    attribute :next,           String
    has_many  :titleDownloads, TitleDownload
    attribute :totalResults,   Integer
  end

end

__loading_end(__FILE__)
