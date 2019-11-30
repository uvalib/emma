# app/records/bs/record/title_metadata_complete.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::TitleMetadataComplete
#
# @attr [Boolean]                             adultContent
# @attr [Boolean]                             allowRecommend
# @attr [Array<Bs::Record::Name>]             arrangers            *deprecated*
# @attr [Array<Bs::Record::ArtifactMetadata>] artifacts
# @attr [Array<Bs::Record::Name>]             authors              *deprecated*
# @attr [Boolean]                             available
# @attr [String]                              bookshareId
# @attr [Array<Bs::Record::Category>]         categories
# @attr [Array<Bs::Record::Name>]             composers            *deprecated*
# @attr [Array<ContentWarning>]               contentWarnings
# @attr [Array<Bs::Record::Contributor>]      contributors
# @attr [String]                              copyright
# @attr [IsoYear]                             copyrightDate
# @attr [Array<String>]                       countries
# @attr [Integer]                             dtbookSize
# @attr [String]                              externalCategoryCode
# @attr [Array<Bs::Record::Format>]           formats
# @attr [Array<Bs::Record::Grade>]            grades
# @attr [Boolean]                             hasChordSymbols
# @attr [String]                              instruments
# @attr [String]                              isbn13
# @attr [String]                              key
# @attr [Array<String>]                       languages
# @attr [IsoDate]                             lastUpdatedDate
# @attr [Array<Bs::Record::Link>]             links
# @attr [Array<Bs::Record::Name>]             lyricists            *deprecated*
# @attr [String]                              movementNumber
# @attr [String]                              movementTitle
# @attr [String]                              musicLayout
# @attr [String]                              musicScoreType
# @attr [String]                              notes
# @attr [Integer]                             numImages
# @attr [Integer]                             numPages
# @attr [String]                              opus
# @attr [String]                              proofreader
# @attr [IsoDate]                             publishDate
# @attr [String]                              publisher
# @attr [Array<String>]                       relatedIsbns
# @attr [String]                              replacementId
# @attr [String]                              seriesNumber
# @attr [String]                              seriesSubtitle
# @attr [String]                              seriesTitle
# @attr [String]                              site
# @attr [String]                              submitter
# @attr [String]                              subtitle
# @attr [String]                              synopsis
# @attr [String]                              title
# @attr [String]                              titleContentType
# @attr [String]                              titleSource
# @attr [Array<Bs::Record::Name>]             translators          *deprecated*
# @attr [Bs::Record::UsageRestriction]        usageRestriction
# @attr [String]                              vocalParts
# @attr [IsoDate]                             withdrawalDate
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_metadata_complete
#
# == Implementation Notes
# Similar to Bs::Message::TitleMetadataDetail, but without these fields:
#   :edition
#   :readingAgeMaximum
#   :readingAgeMinimum
# And adding fields:
#   :dtbookSize
#   :lastUpdatedDate
#   :numImages
#   :proofreader
#   :submitter
#   :titleSource
#   :withdrawalDate
#
# noinspection DuplicatedCode
class Bs::Record::TitleMetadataComplete < Bs::Api::Record

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  schema do
    attribute :adultContent,         Boolean
    attribute :allowRecommend,       Boolean
    has_many  :arrangers,            Bs::Record::Name       # NOTE: deprecated
    has_many  :artifacts,            Bs::Record::ArtifactMetadata
    has_many  :authors,              Bs::Record::Name       # NOTE: deprecated
    attribute :available,            Boolean
    attribute :bookshareId,          String
    has_many  :categories,           Bs::Record::Category
    has_many  :composers,            Bs::Record::Name       # NOTE: deprecated
    has_many  :contentWarnings,      ContentWarning
    has_many  :contributors,         Bs::Record::Contributor
    attribute :copyright,            String
    attribute :copyrightDate,        IsoYear
    has_many  :countries,            String
    attribute :dtbookSize,           Integer
    attribute :externalCategoryCode, String
    has_many  :formats,              Bs::Record::Format
    has_many  :grades,               Bs::Record::Grade
    attribute :hasChordSymbols,      Boolean
    attribute :instruments,          String
    attribute :isbn13,               String
    attribute :key,                  String
    has_many  :languages,            String
    attribute :lastUpdatedDate,      IsoDate
    has_many  :links,                Bs::Record::Link
    has_many  :lyricists,            Bs::Record::Name       # NOTE: deprecated
    attribute :movementNumber,       String
    attribute :movementTitle,        String
    attribute :musicLayout,          String
    attribute :musicScoreType,       String
    attribute :notes,                String
    attribute :numImages,            Integer
    attribute :numPages,             Integer
    attribute :opus,                 String
    attribute :proofreader,          String
    attribute :publishDate,          IsoDate
    attribute :publisher,            String
    has_many  :relatedIsbns,         String
    attribute :replacementId,        String
    attribute :seriesNumber,         String
    attribute :seriesSubtitle,       String
    attribute :seriesTitle,          String
    attribute :site,                 String
    attribute :submitter,            String
    attribute :subtitle,             String
    attribute :synopsis,             String
    attribute :title,                String
    attribute :titleContentType,     String
    attribute :titleSource,          String
    has_many  :translators,          Bs::Record::Name       # NOTE: deprecated
    has_one   :usageRestriction,     Bs::Record::UsageRestriction
    attribute :vocalParts,           String
    attribute :withdrawalDate,       IsoDate
  end

end

__loading_end(__FILE__)
