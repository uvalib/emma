# app/models/api/title_download.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/artifact_methods'
require_relative 'common/link_methods'
require_relative 'common/title_methods'
require_relative 'status_model'

# Api::TitleDownload
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_download
#
class Api::TitleDownload < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

  schema do
    has_many  :authors,        Api::Name
    attribute :dateDownloaded, String
    attribute :downloadedBy,   String
    attribute :downloadedFor,  String
    has_one   :format,         Api::Format
    has_many  :links,          Api::Link
    has_one   :status,         Api::StatusModel
    attribute :title,          String
  end

end

__loading_end(__FILE__)
