# app/models/api/assigned_title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/name'
require 'api/format'
require 'api/link'

# Api::AssignedTitleMetadataSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_assigned_title_metadata_summary
#
class Api::AssignedTitleMetadataSummary < Api::Record::Base

  schema do
    attribute :assignedBy,       String
    has_many  :authors,          Name
    attribute :available,        Boolean
    attribute :bookshareId,      String
    has_many  :composers,        Name
    attribute :copyrightDate,    String
    attribute :dateAdded,        String
    attribute :dateDownloaded,   String # TODO: ???
    has_many  :formats,          Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Link
    attribute :publishDate,      String # TODO: ???
    attribute :seriesNumber,     String
    attribute :seriesTitle,      String
    attribute :subtitle,         String
    attribute :synopsis,         String
    attribute :title,            String
    attribute :titleContentType, String
    attribute :vocalParts,       String
  end

end

__loading_end(__FILE__)
