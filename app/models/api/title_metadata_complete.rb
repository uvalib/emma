# app/models/api/title_metadata_complete.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/artifact_methods'
require_relative 'common/link_methods'
require_relative 'common/title_methods'
require_relative 'artifact_metadata'
require_relative 'category'
require_relative 'grade'
require_relative 'usage_restriction'

# Api::TitleMetadataComplete
#
# @attr [Boolean]                      adultContent
# @attr [Boolean]                      allowRecommend
# @attr [Array<Api::Name>]             arrangers            *deprecated*
# @attr [Array<Api::ArtifactMetadata>] artifacts
# @attr [Array<Api::Name>]             authors              *deprecated*
# @attr [Boolean]                      available
# @attr [String]                       bookshareId
# @attr [Array<Api::Category>]         categories
# @attr [Array<Api::Name>]             composers            *deprecated*
# @attr [Array<ContentWarning>]        contentWarnings
# @attr [Array<Api::Contributor>]      contributors
# @attr [String]                       copyright
# @attr [String]                       copyrightDate
# @attr [Array<String>]                countries
# @attr [Integer]                      dtbookSize
# @attr [String]                       externalCategoryCode
# @attr [Array<Api::Format>]           formats
# @attr [Array<Api::Grade>]            grades
# @attr [Boolean]                      hasChordSymbols
# @attr [String]                       instruments
# @attr [String]                       isbn13
# @attr [String]                       key
# @attr [Array<String>]                languages
# @attr [String]                       lastUpdatedDate
# @attr [Array<Api::Link>]             links
# @attr [Array<Api::Name>]             lyricists            *deprecated*
# @attr [String]                       movementNumber
# @attr [String]                       movementTitle
# @attr [String]                       musicLayout
# @attr [String]                       musicScoreType
# @attr [String]                       notes
# @attr [Integer]                      numImages
# @attr [Integer]                      numPages
# @attr [String]                       opus
# @attr [String]                       proofreader
# @attr [String]                       publishDate
# @attr [String]                       publisher
# @attr [Array<String>]                relatedIsbns
# @attr [String]                       replacementId
# @attr [String]                       seriesNumber
# @attr [String]                       seriesSubtitle
# @attr [String]                       seriesTitle
# @attr [String]                       site
# @attr [String]                       submitter
# @attr [String]                       subtitle
# @attr [String]                       synopsis
# @attr [String]                       title
# @attr [String]                       titleContentType
# @attr [String]                       titleSource
# @attr [Array<Api::Name>]             translators          *deprecated*
# @attr [Api::UsageRestriction]        usageRestriction
# @attr [String]                       vocalParts
# @attr [String]                       withdrawalDate
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_metadata_complete
#
# == Implementation Notes
# Similar to ApiTitleMetadataDetail, but without the following fields:
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
class Api::TitleMetadataComplete < Api::Record::Base

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
    attribute :copyrightDate,        String
    has_many  :countries,            String
    attribute :dtbookSize,           Integer
    attribute :externalCategoryCode, String
    has_many  :formats,              Api::Format
    has_many  :grades,               Api::Grade
    attribute :hasChordSymbols,      Boolean
    attribute :instruments,          String
    attribute :isbn13,               String
    attribute :key,                  String
    has_many  :languages,            String
    attribute :lastUpdatedDate,      String
    has_many  :links,                Api::Link
    has_many  :lyricists,            Api::Name              # NOTE: deprecated
    attribute :movementNumber,       String
    attribute :movementTitle,        String
    attribute :musicLayout,          String
    attribute :musicScoreType,       String
    attribute :notes,                String
    attribute :numImages,            Integer
    attribute :numPages,             Integer
    attribute :opus,                 String
    attribute :proofreader,          String
    attribute :publishDate,          String
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
    has_many  :translators,          Api::Name              # NOTE: deprecated
    has_one   :usageRestriction,     Api::UsageRestriction
    attribute :vocalParts,           String
    attribute :withdrawalDate,       String
  end

end

__loading_end(__FILE__)
