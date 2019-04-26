# app/models/api_title_metadata_detail.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/name'
require 'api/artifact_metadata'
require 'api/category'
require 'api/format'
require 'api/grade'
require 'api/link'
require 'api/usage_restriction'

# ApiTitleMetadataDetail
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_detail
#
class ApiTitleMetadataDetail < Api::Message

  schema do
    attribute :adultContent,         Boolean
    attribute :allowRecommended,     Boolean
    has_many  :arrangers,            Name
    has_many  :artifacts,            ArtifactMetadata
    has_many  :authors,              Name
    attribute :available,            Boolean
    attribute :bookshareId,          String
    has_many  :categories,           Category
    has_many  :composers,            Name
    attribute :copyright,            String
    attribute :copyrightDate,        String # TODO: ???
    has_many  :countries,            String
    attribute :edition,              String
    attribute :externalCategoryCode, String
    has_many  :formats,              Format
    has_many  :grades,               Grade
    attribute :hasChordSymbols,      String
    attribute :instruments,          String
    attribute :isbn13,               String
    attribute :key,                  String
    has_many  :languages,            String
    has_many  :links,                Link
    has_many  :lyricists,            Name
    attribute :movementNumber,       String
    attribute :movementTitle,        String
    attribute :musicLayout,          String
    attribute :musicScoreType,       String
    attribute :numPages,             Integer
    attribute :opus,                 String
    attribute :publishDate,          String
    attribute :publisher,            String
    attribute :readingAgeMaximum,    Integer
    attribute :readingAgeMinimum,    Integer
    has_many  :relatedIsbns,         String
    attribute :seriesNumber,         String
    attribute :seriesSubtitle,       String
    attribute :seriesTitle,          String
    attribute :subtitle,             String
    attribute :synopsis,             String
    attribute :title,                String
    attribute :titleContentType,     String
    attribute :titleSource,          String
    has_many  :translators,          Name
    attribute :usageRestriction,     UsageRestriction
    attribute :vocalParts,           String
  end

end

__loading_end(__FILE__)
