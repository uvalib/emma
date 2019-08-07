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
# @attr [Array<Api::Name>]        arrangers         *deprecated*
# @attr [Array<Api::Name>]        authors           *deprecated*
# @attr [Boolean]                 available
# @attr [String]                  bookshareId
# @attr [Array<Api::Name>]        composers         *deprecated*
# @attr [Array<ContentWarning>]   contentWarnings
# @attr [Array<Api::Contributor>] contributors
# @attr [String]                  copyrightDate
# @attr [Array<Api::Format>]      formats
# @attr [String]                  instruments
# @attr [String]                  isbn13
# @attr [Array<String>]           languages
# @attr [Array<Api::Link>]        links
# @attr [Array<Api::Name>]        lyricists         *deprecated*
# @attr [String]                  publishDate
# @attr [String]                  seriesNumber
# @attr [String]                  seriesTitle
# @attr [String]                  subtitle
# @attr [String]                  synopsis
# @attr [String]                  title
# @attr [String]                  titleContentType
# @attr [Array<Api::Name>]        translators       *deprecated*
# @attr [String]                  vocalParts
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_metadata_summary
#
# NOTE: This duplicates:
# @see ApiTitleMetadataSummary
#
# == Implementation Notes
# Similar to Api::AssignedTitleMetadataSummary, but without these fields:
#   :assignedBy
#   :dateAdded
#   :dateDownloaded
# And adds these fields:
#   :arrangers
#   :contentWarnings
#   :contributors
#   :lyricists
#   :translators
#
# noinspection DuplicatedCode
class Api::TitleMetadataSummary < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

  schema do
    has_many  :arrangers,        Api::Name                  # NOTE: deprecated
    has_many  :authors,          Api::Name                  # NOTE: deprecated
    attribute :available,        Boolean
    attribute :bookshareId,      String
    has_many  :composers,        Api::Name                  # NOTE: deprecated
    has_many  :contentWarnings,  ContentWarning
    has_many  :contributors,     Api::Contributor
    attribute :copyrightDate,    String
    has_many  :formats,          Api::Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Api::Link
    has_many  :lyricists,        Api::Name                  # NOTE: deprecated
    attribute :publishDate,      String
    attribute :seriesNumber,     String
    attribute :seriesTitle,      String
    attribute :subtitle,         String
    attribute :synopsis,         String
    attribute :title,            String
    attribute :titleContentType, String
    has_many  :translators,      Api::Name                  # NOTE: deprecated
    attribute :vocalParts,       String
  end

end

__loading_end(__FILE__)
