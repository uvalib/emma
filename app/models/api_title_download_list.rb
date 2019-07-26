# app/models/api_title_download_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/link'
require_relative 'api/title_download'
require_relative 'api/common/link_methods'

# ApiTitleDownloadList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_download_list
#
class ApiTitleDownloadList < Api::Message

  schema do
    has_many  :allows,         AllowsType
    has_many  :links,          Api::Link
    attribute :next,           String
    has_many  :titleDownloads, Api::TitleDownload
    attribute :totalResults,   Integer
  end

  include Api::Common::LinkMethods

end

__loading_end(__FILE__)
