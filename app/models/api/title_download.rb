# app/models/api/title_download.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/name'
require 'api/format'
require 'api/link'
require 'api/status_model'

# Api::TitleDownload
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_download
#
class Api::TitleDownload < Api::Record::Base

  schema do
    has_many  :authors,        Name
    attribute :dateDownloaded, String
    attribute :downloadedBy,   String
    attribute :downloadedFor,  String
    attribute :format,         Format
    has_many  :links,          Link
    attribute :status,         StatusModel
    attribute :title,          String
  end

end

__loading_end(__FILE__)
