# app/models/api_title_metadata_detail.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/artifact_metadata'
require_relative 'api/category'
require_relative 'api/format'
require_relative 'api/grade'
require_relative 'api/link'
require_relative 'api/name'
require_relative 'api/usage_restriction'
require_relative 'api/common/artifact_methods'
require_relative 'api/common/link_methods'
require_relative 'api/common/title_methods'

# ApiTitleMetadataDetail
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_detail
#
# == Implementation Notes
# Similar to Api::TitleMetadataComplete, but without the following fields:
#   :dtbookSize
#   :numImages
#   :proofreader
#   :submitter
#   :withdrawalDate
# And adds fields:
#   :edition
#   :readingAgeMaximum
#   :readingAgeMinimum
#
class ApiTitleMetadataDetail < Api::Message

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
    attribute :copyrightDate,        String # TODO: ???
    has_many  :countries,            String
    attribute :edition,              String
    attribute :externalCategoryCode, String
    has_many  :formats,              Api::Format
    has_many  :grades,               Api::Grade
    attribute :hasChordSymbols,      String
    attribute :instruments,          String
    attribute :isbn13,               String
    attribute :key,                  String
    has_many  :languages,            String
    has_many  :links,                Api::Link
    has_many  :lyricists,            Api::Name
    attribute :movementNumber,       String
    attribute :movementTitle,        String
    attribute :musicLayout,          String
    attribute :musicScoreType,       String
    attribute :notes,                String
    attribute :numPages,             Integer
    attribute :opus,                 String
    attribute :publishDate,          String
    attribute :publisher,            String
    attribute :readingAgeMaximum,    Integer
    attribute :readingAgeMinimum,    Integer
    has_many  :relatedIsbns,         String
    attribute :replacementId,        String
    attribute :seriesNumber,         String
    attribute :seriesSubtitle,       String
    attribute :seriesTitle,          String
    attribute :subtitle,             String
    attribute :synopsis,             String
    attribute :title,                String
    attribute :titleContentType,     String
    attribute :titleSource,          String
    has_many  :translators,          Api::Name
    has_one   :usageRestriction,     Api::UsageRestriction
    attribute :vocalParts,           String
  end

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

end

__loading_end(__FILE__)
