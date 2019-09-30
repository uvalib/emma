# app/models/api_title_metadata_detail.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiTitleMetadataDetail
#
# @attr [Boolean]                      adultContent
# @attr [Boolean]                      allowRecommend
# @attr [Array<Api::Name>]             arrangers              *deprecated*
# @attr [Array<Api::ArtifactMetadata>] artifacts
# @attr [Array<Api::Name>]             authors                *deprecated*
# @attr [Boolean]                      available
# @attr [String]                       bookshareId
# @attr [Array<Api::Category>]         categories
# @attr [Array<Api::Name>]             composers              *deprecated*
# @attr [Array<ContentWarning>]        contentWarnings
# @attr [Array<Api::Contributor>]      contributors
# @attr [String]                       copyright
# @attr [IsoYear]                      copyrightDate
# @attr [Array<String>]                countries
# @attr [String]                       edition
# @attr [String]                       externalCategoryCode
# @attr [Array<Api::Format>]           formats
# @attr [Array<Api::Grade>]            grades
# @attr [Boolean]                      hasChordSymbols
# @attr [String]                       instruments
# @attr [String]                       isbn13
# @attr [String]                       key
# @attr [Array<String>]                languages
# @attr [Array<Api::Link>]             links
# @attr [Array<Api::Name>]             lyricists              *deprecated*
# @attr [Boolean]                      marrakeshAvailable
# @attr [String]                       movementNumber
# @attr [String]                       movementTitle
# @attr [String]                       musicLayout
# @attr [String]                       musicScoreType
# @attr [String]                       notes
# @attr [Integer]                      numPages
# @attr [String]                       opus
# @attr [IsoDate]                      publishDate
# @attr [String]                       publisher
# @attr [Integer]                      readingAgeMaximum
# @attr [Integer]                      readingAgeMinimum
# @attr [Array<String>]                relatedIsbns
# @attr [String]                       replacementId
# @attr [String]                       seriesNumber
# @attr [String]                       seriesSubtitle
# @attr [String]                       seriesTitle
# @attr [String]                       site
# @attr [String]                       subtitle
# @attr [String]                       synopsis
# @attr [String]                       title
# @attr [String]                       titleContentType
# @attr [Array<Api::Name>]             translators            *deprecated*
# @attr [Api::UsageRestriction]        usageRestriction
# @attr [String]                       vocalParts
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_metadata_detail
#
# == Implementation Notes
# Similar to Api::TitleMetadataComplete, but without the following fields:
#   :dtbookSize
#   :lastUpdatedDate
#   :numImages
#   :proofreader
#   :submitter
#   :titleSource
#   :withdrawalDate
# And adding fields:
#   :edition
#   :marrakeshAvailable
#   :readingAgeMaximum
#   :readingAgeMinimum
#   :site
#
# noinspection DuplicatedCode
class ApiTitleMetadataDetail < Api::Message

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

  schema do
    attribute :adultContent,         Boolean
    attribute :allowRecommend,       Boolean
    has_many  :arrangers,            Api::Name              # NOTE: deprecated
    has_many  :artifacts,            Api::ArtifactMetadata
    has_many  :authors,              Api::Name              # NOTE: deprecated
    attribute :available,            Boolean
    attribute :bookshareId,          String
    has_many  :categories,           Api::Category
    has_many  :composers,            Api::Name              # NOTE: deprecated
    has_many  :contentWarnings,      ContentWarning
    has_many  :contributors,         Api::Contributor
    attribute :copyright,            String
    attribute :copyrightDate,        IsoYear
    has_many  :countries,            String
    attribute :edition,              String
    attribute :externalCategoryCode, String
    has_many  :formats,              Api::Format
    has_many  :grades,               Api::Grade
    attribute :hasChordSymbols,      Boolean
    attribute :instruments,          String
    attribute :isbn13,               String
    attribute :key,                  String
    has_many  :languages,            String
    has_many  :links,                Api::Link
    has_many  :lyricists,            Api::Name              # NOTE: deprecated
    attribute :marrakeshAvailable,   Boolean
    attribute :movementNumber,       String
    attribute :movementTitle,        String
    attribute :musicLayout,          String
    attribute :musicScoreType,       String
    attribute :notes,                String
    attribute :numPages,             Integer
    attribute :opus,                 String
    attribute :publishDate,          IsoDate
    attribute :publisher,            String
    attribute :readingAgeMaximum,    Integer
    attribute :readingAgeMinimum,    Integer
    has_many  :relatedIsbns,         String
    attribute :replacementId,        String
    attribute :seriesNumber,         String
    attribute :seriesSubtitle,       String
    attribute :seriesTitle,          String
    attribute :site,                 String
    attribute :subtitle,             String
    attribute :synopsis,             String
    attribute :title,                String
    attribute :titleContentType,     String
    has_many  :translators,          Api::Name              # NOTE: deprecated
    has_one   :usageRestriction,     Api::UsageRestriction
    attribute :vocalParts,           String
  end

end

__loading_end(__FILE__)
