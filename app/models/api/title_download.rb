# app/models/api/title_download.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::TitleDownload
#
# @attr [Array<Api::Name>] authors          *deprecated*
# @attr [IsoDate]          dateDownloaded
# @attr [String]           downloadedBy
# @attr [String]           downloadedFor
# @attr [Api::Format]      format
# @attr [Array<Api::Link>] links
# @attr [Api::StatusModel] status
# @attr [String]           title
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_download
#
class Api::TitleDownload < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

  schema do
    has_many  :authors,        Api::Name                    # NOTE: deprecated
    attribute :dateDownloaded, IsoDate
    attribute :downloadedBy,   String
    attribute :downloadedFor,  String
    has_one   :format,         Api::Format
    has_many  :links,          Api::Link
    has_one   :status,         Api::StatusModel
    attribute :title,          String
  end

end

__loading_end(__FILE__)
