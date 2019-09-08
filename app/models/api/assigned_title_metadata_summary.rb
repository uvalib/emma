# app/models/api/assigned_title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::AssignedTitleMetadataSummary
#
# @attr [String]             assignedBy
# @attr [Array<Api::Name>]   authors            *deprecated*
# @attr [Boolean]            available
# @attr [String]             bookshareId
# @attr [Array<Api::Name>]   composers          *deprecated*
# @attr [String]             copyrightDate
# @attr [String]             dateAdded
# @attr [String]             dateDownloaded
# @attr [Array<Api::Format>] formats
# @attr [String]             instruments
# @attr [String]             isbn13
# @attr [Array<String>]      languages
# @attr [Array<Api::Link>]   links
# @attr [String]             publishDate
# @attr [String]             seriesNumber
# @attr [String]             seriesTitle
# @attr [String]             subtitle
# @attr [String]             synopsis
# @attr [String]             title
# @attr [String]             titleContentType
# @attr [String]             vocalParts
#
# @see https://apidocs.bookshare.org/reference/index.html#_assigned_title_metadata_summary
#
# == Implementation Notes
# Similar to Api::TitleMetadataSummary, but without these fields:
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
class Api::AssignedTitleMetadataSummary < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

  schema do
    attribute :assignedBy,       String
    has_many  :authors,          Api::Name                  # NOTE: deprecated
    attribute :available,        Boolean
    attribute :bookshareId,      String
    has_many  :composers,        Api::Name                  # NOTE: deprecated
    attribute :copyrightDate,    String
    attribute :dateAdded,        String
    attribute :dateDownloaded,   String
    has_many  :formats,          Api::Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Api::Link
    attribute :publishDate,      String
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
