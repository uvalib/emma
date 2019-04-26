# app/models/api/download_timeframe.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/link'

# Api::DownloadTimeframe
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_download_timeframe
#
class Api::DownloadTimeframe < Api::Record::Base

  schema do
    attribute :name, Timeframe
  end

end

__loading_end(__FILE__)
