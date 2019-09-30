# app/models/api/title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::TitleMetadataSummary
#
# @attr [Array<Api::Name>]        arrangers         *deprecated*
# @attr [Array<Api::Name>]        authors           *deprecated*
# @attr [Boolean]                 available
# @attr [String]                  bookshareId
# @attr [Array<Api::Category>]    categories
# @attr [Array<Api::Name>]        composers         *deprecated*
# @attr [Array<ContentWarning>]   contentWarnings
# @attr [Array<Api::Contributor>] contributors
# @attr [IsoYear]                 copyrightDate
# @attr [Array<Api::Format>]      formats
# @attr [String]                  instruments
# @attr [String]                  isbn13
# @attr [Array<String>]           languages
# @attr [Array<Api::Link>]        links
# @attr [Array<Api::Name>]        lyricists         *deprecated*
# @attr [IsoDate]                 publishDate
# @attr [Integer]                 readingAgeMaximum
# @attr [Integer]                 readingAgeMinimum
# @attr [String]                  seriesNumber
# @attr [String]                  seriesTitle
# @attr [String]                  site
# @attr [String]                  subtitle
# @attr [String]                  synopsis
# @attr [String]                  title
# @attr [String]                  titleContentType
# @attr [Array<Api::Name>]        translators       *deprecated*
# @attr [String]                  vocalParts
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_metadata_summary
#
# NOTE: This duplicates:
# @see ApiTitleMetadataSummary
#
# == Implementation Notes
# Similar to Api::AssignedTitleMetadataSummary, but without these fields:
#   :assignedBy
#   :dateAdded
#   :dateDownloaded
# And adds these fields:
#   :arrangers
#   :categories
#   :contentWarnings
#   :contributors
#   :lyricists
#   :readingAgeMaximum
#   :readingAgeMinimum
#   :site
#   :translators
#
# noinspection DuplicatedCode
class Api::TitleMetadataSummary < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

  schema do
    has_many  :arrangers,         Api::Name                 # NOTE: deprecated
    has_many  :authors,           Api::Name                 # NOTE: deprecated
    attribute :available,         Boolean
    attribute :bookshareId,       String
    has_many  :categories,        Api::Category
    has_many  :composers,         Api::Name                 # NOTE: deprecated
    has_many  :contentWarnings,   ContentWarning
    has_many  :contributors,      Api::Contributor
    attribute :copyrightDate,     IsoYear
    has_many  :formats,           Api::Format
    attribute :instruments,       String
    attribute :isbn13,            String
    has_many  :languages,         String
    has_many  :links,             Api::Link
    has_many  :lyricists,         Api::Name                 # NOTE: deprecated
    attribute :publishDate,       IsoDate
    attribute :readingAgeMaximum, Integer
    attribute :readingAgeMinimum, Integer
    attribute :seriesNumber,      String
    attribute :seriesTitle,       String
    attribute :site,              String
    attribute :subtitle,          String
    attribute :synopsis,          String
    attribute :title,             String
    attribute :titleContentType,  String
    has_many  :translators,       Api::Name                 # NOTE: deprecated
    attribute :vocalParts,        String
  end

end

__loading_end(__FILE__)
