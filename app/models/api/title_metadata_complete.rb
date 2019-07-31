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
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_complete
#
# == Implementation Notes
# Similar to ApiTitleMetadataDetail, but without the following fields:
#   :edition
#   :readingAgeMaximum
#   :readingAgeMinimum
# And adds fields:
#   :dtbookSize
#   :numImages
#   :proofreader
#   :submitter
#   :withdrawalDate
#
class Api::TitleMetadataComplete < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

  schema do
    attribute :adultContent,         Boolean
    attribute :allowRecommend,       Boolean
    has_many  :arrangers,            Api::Name
    has_many  :artifacts,            Api::ArtifactMetadata
    has_many  :authors,              Api::Name
    attribute :available,            Boolean
    attribute :bookshareId,          String
    has_many  :categories,           Api::Category
    has_many  :composers,            Api::Name
    has_many  :contentWarnings,      String
    attribute :copyright,            String
    attribute :copyrightDate,        String
    has_many  :countries,            String
    attribute :dtbookSize,           Integer
    attribute :externalCategoryCode, String
    has_many  :formats,              Api::Format
    has_many  :grades,               Api::Grade
    attribute :hasChordSymbols,      String
    attribute :instruments,          String
    attribute :isbn13,               String
    attribute :key,                  String
    has_many  :languages,            String
    attribute :lastUpdatedDate,      String
    has_many  :links,                Api::Link
    has_many  :lyricists,            Api::Name
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
    attribute :submitter,            String
    attribute :subtitle,             String
    attribute :synopsis,             String
    attribute :title,                String
    attribute :titleContentType,     String
    attribute :titleSource,          String
    has_many  :translators,          Api::Name
    has_one   :usageRestriction,     Api::UsageRestriction
    attribute :vocalParts,           String
    attribute :withdrawalDate,       String
  end

end

__loading_end(__FILE__)
