# app/records/bs/record/assigned_title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::AssignedTitleMetadataSummary
#
# @attr [String]                    assignedBy
# @attr [Array<Bs::Record::Name>]   authors            *deprecated*
# @attr [Boolean]                   available
# @attr [String]                    bookshareId
# @attr [Array<Bs::Record::Name>]   composers          *deprecated*
# @attr [IsoYear]                   copyrightDate
# @attr [String]                    dateAdded
# @attr [String]                    dateDownloaded
# @attr [Array<Bs::Record::Format>] formats
# @attr [String]                    instruments
# @attr [String]                    isbn13
# @attr [Array<String>]             languages
# @attr [Array<Bs::Record::Link>]   links
# @attr [IsoDate]                   publishDate
# @attr [String]                    seriesNumber
# @attr [String]                    seriesTitle
# @attr [String]                    subtitle
# @attr [String]                    synopsis
# @attr [String]                    title
# @attr [String]                    titleContentType
# @attr [String]                    vocalParts
#
# @see https://apidocs.bookshare.org/reference/index.html#_assigned_title_metadata_summary
#
# == Implementation Notes
# Similar to Bs::Record::TitleMetadataSummary, but without these fields:
#   :arrangers
#   :contentWarnings
#   :contributors
#   :lyricists
#   :translators
# And adds these fields:
#   :assignedBy
#   :dateAdded
#   :dateDownloaded
#
class Bs::Record::AssignedTitleMetadataSummary < Bs::Api::Record

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  schema do
    attribute :assignedBy,       String
    has_many  :authors,          Bs::Record::Name           # NOTE: deprecated
    attribute :available,        Boolean
    attribute :bookshareId,      String
    has_many  :composers,        Bs::Record::Name           # NOTE: deprecated
    attribute :copyrightDate,    IsoYear
    attribute :dateAdded,        String
    attribute :dateDownloaded,   String
    has_many  :formats,          Bs::Record::Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Bs::Record::Link
    attribute :publishDate,      IsoDate
    attribute :seriesNumber,     String
    attribute :seriesTitle,      String
    attribute :subtitle,         String
    attribute :synopsis,         String
    attribute :title,            String
    attribute :titleContentType, String
    attribute :vocalParts,       String
  end

end

__loading_end(__FILE__)
