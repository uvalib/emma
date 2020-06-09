# app/records/bs/record/title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::TitleMetadataSummary
#
# @attr [Array<Bs::Record::Name>]        arrangers         *deprecated*
# @attr [Array<Bs::Record::Name>]        authors           *deprecated*
# @attr [Boolean]                        available
# @attr [String]                         bookshareId
# @attr [Array<Bs::Record::Category>]    categories
# @attr [Array<Bs::Record::Name>]        composers         *deprecated*
# @attr [Array<ContentWarning>]          contentWarnings
# @attr [Array<Bs::Record::Contributor>] contributors
# @attr [IsoYear]                        copyrightDate
# @attr [Array<Bs::Record::Format>]      formats
# @attr [String]                         instruments
# @attr [String]                         isbn13
# @attr [Array<String>]                  languages
# @attr [Array<Bs::Record::Link>]        links
# @attr [Array<Bs::Record::Name>]        lyricists         *deprecated*
# @attr [IsoDate]                        publishDate
# @attr [Integer]                        readingAgeMaximum
# @attr [Integer]                        readingAgeMinimum
# @attr [String]                         seriesNumber
# @attr [String]                         seriesTitle
# @attr [String]                         site
# @attr [String]                         subtitle
# @attr [String]                         synopsis
# @attr [String]                         title
# @attr [String]                         titleContentType
# @attr [Array<Bs::Record::Name>]        translators       *deprecated*
# @attr [String]                         vocalParts
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_metadata_summary
#
# NOTE: This duplicates:
# @see Bs::Message::TitleMetadataSummary
#
# == Implementation Notes
# Similar to Bs::Record::AssignedTitleMetadataSummary, but without fields:
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
#--
# noinspection DuplicatedCode
#++
class Bs::Record::TitleMetadataSummary < Bs::Api::Record

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  schema do
    has_many  :arrangers,         Bs::Record::Name          # NOTE: deprecated
    has_many  :authors,           Bs::Record::Name          # NOTE: deprecated
    attribute :available,         Boolean
    attribute :bookshareId,       String
    has_many  :categories,        Bs::Record::Category
    has_many  :composers,         Bs::Record::Name          # NOTE: deprecated
    has_many  :contentWarnings,   ContentWarning
    has_many  :contributors,      Bs::Record::Contributor
    attribute :copyrightDate,     IsoYear
    has_many  :formats,           Bs::Record::Format
    attribute :instruments,       String
    attribute :isbn13,            String
    has_many  :languages,         String
    has_many  :links,             Bs::Record::Link
    has_many  :lyricists,         Bs::Record::Name          # NOTE: deprecated
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
    has_many  :translators,       Bs::Record::Name          # NOTE: deprecated
    attribute :vocalParts,        String
  end

end

__loading_end(__FILE__)
