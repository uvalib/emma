# app/models/api_title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/title_metadata_summary'
require_relative 'api/common/artifact_methods'

# ApiTitleMetadataSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_summary
#
# NOTE: This duplicates:
# @see Api::TitleMetadataSummary
#
class ApiTitleMetadataSummary < Api::Message

  schema do
    has_many  :arrangers,        Api::Name
    has_many  :authors,          Api::Name
    attribute :available,        Boolean
    attribute :bookshareId,      String
    has_many  :composers,        Api::Name
    has_many  :contentWarnings,  String
    attribute :copyrightDate,    String
    has_many  :formats,          Api::Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Api::Link
    has_many  :lyricists,        Api::Name
    attribute :publishDate,      String
    attribute :seriesNumber,     String
    attribute :seriesTitle,      String
    attribute :subtitle,         String
    attribute :synopsis,         String
    attribute :title,            String
    attribute :titleContentType, String
    has_many  :translators,      Api::Name
    attribute :vocalParts,       String
  end

  include Api::Common::TitleMethods
  include Api::Common::ArtifactMethods

end

__loading_end(__FILE__)
