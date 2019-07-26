# app/models/api/assigned_title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'format'
require_relative 'link'
require_relative 'name'
require_relative 'common/artifact_methods'
require_relative 'common/link_methods'
require_relative 'common/title_methods'

# Api::AssignedTitleMetadataSummary
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_assigned_title_metadata_summary
#
class Api::AssignedTitleMetadataSummary < Api::Record::Base

  schema do
    attribute :assignedBy,       String
    has_many  :authors,          Api::Name
    attribute :available,        Boolean
    attribute :bookshareId,      String
    has_many  :composers,        Api::Name
    attribute :copyrightDate,    String
    attribute :dateAdded,        String
    attribute :dateDownloaded,   String # TODO: ???
    has_many  :formats,          Api::Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Api::Link
    attribute :publishDate,      String # TODO: ???
    attribute :seriesNumber,     String
    attribute :seriesTitle,      String
    attribute :subtitle,         String
    attribute :synopsis,         String
    attribute :title,            String
    attribute :titleContentType, String
    attribute :vocalParts,       String
  end

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

end

__loading_end(__FILE__)
