# app/models/api/title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'common/artifact_methods'
require_relative 'common/link_methods'
require_relative 'common/title_methods'

# Api::TitleMetadataSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_summary
#
# NOTE: This duplicates:
# @see ApiTitleMetadataSummary
#
# noinspection DuplicatedCode
class Api::TitleMetadataSummary < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

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

end

__loading_end(__FILE__)
