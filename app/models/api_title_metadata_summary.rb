# app/models/api_title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/title_metadata_summary'

# ApiTitleMetadataSummary
#
# NOTE: This duplicates Api::TitleMetadataSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_title_metadata_summary
#
class ApiTitleMetadataSummary < Api::Message

  schema do
    has_many  :arrangers,        Name
    has_many  :authors,          Name
    attribute :available,        Boolean
    attribute :bookshareId,      String
    has_many  :composers,        Name
    attribute :copyrightDate,    String
    has_many  :formats,          Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Link
    has_many  :lyricists,        Name
    attribute :publishDate,      String
    attribute :seriesNumber,     String
    attribute :seriesTitle,      String
    attribute :subtitle,         String
    attribute :synopsis,         String
    attribute :title,            String
    attribute :titleContentType, String
    has_many  :translators,      Name
    attribute :vocalParts,       String
  end

end

__loading_end(__FILE__)
