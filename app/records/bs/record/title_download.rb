# app/records/bs/record/title_download.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::TitleDownload
#
# @attr [Array<Bs::Record::Name>] authors          *deprecated*
# @attr [IsoDate]                 dateDownloaded
# @attr [String]                  downloadedBy
# @attr [String]                  downloadedFor
# @attr [Bs::Record::Format]      format
# @attr [Array<Bs::Record::Link>] links
# @attr [Bs::Record::StatusModel] status
# @attr [String]                  title
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_download
#
class Bs::Record::TitleDownload < Bs::Api::Record

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  schema do
    has_many  :authors,        Bs::Record::Name             # NOTE: deprecated
    has_one   :dateDownloaded, IsoDate
    has_one   :downloadedBy
    has_one   :downloadedFor
    has_one   :format,         Bs::Record::Format
    has_many  :links,          Bs::Record::Link
    has_one   :status,         Bs::Record::StatusModel
    has_one   :title
  end

end

__loading_end(__FILE__)
