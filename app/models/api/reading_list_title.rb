# app/models/api/reading_list_title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::ReadingListTitle
#
# @attr [Array<AllowsType>]  allows
# @attr [Array<Api::Name>]   authors            *deprecated*
# @attr [Boolean]            available
# @attr [String]             award
# @attr [String]             bookshareId
# @attr [String]             category
# @attr [Array<Api::Name>]   composers          *deprecated*
# @attr [String]             copyrightDate
# @attr [String]             dateAdded
# @attr [Array<Api::Format>] formats
# @attr [String]             instruments
# @attr [String]             isbn13
# @attr [Array<String>]      languages
# @attr [Array<Api::Link>]   links
# @attr [Integer]            month
# @attr [String]             publishDate
# @attr [Integer]            ranking
# @attr [String]             seriesNumber
# @attr [String]             seriesTitle
# @attr [String]             subtitle
# @attr [String]             synopsis
# @attr [String]             title
# @attr [String]             titleContentType
# @attr [String]             vocalParts
# @attr [Integer]            year
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_title
#
class Api::ReadingListTitle < Api::Record::Base

  include Api::Common::ArtifactMethods
  include Api::Common::LinkMethods
  include Api::Common::TitleMethods

  schema do
    has_many  :allows,           AllowsType
    has_many  :authors,          Api::Name                  # NOTE: deprecated
    attribute :available,        Boolean
    attribute :award,            String
    attribute :bookshareId,      String
    attribute :category,         String
    has_many  :composers,        Api::Name                  # NOTE: deprecated
    attribute :copyrightDate,    String
    attribute :dateAdded,        String
    has_many  :formats,          Api::Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Api::Link
    attribute :month,            Integer
    attribute :publishDate,      String
    attribute :ranking,          Integer
    attribute :seriesNumber,     String
    attribute :seriesTitle,      String
    attribute :subtitle,         String
    attribute :synopsis,         String
    attribute :title,            String
    attribute :titleContentType, String
    attribute :vocalParts,       String
    attribute :year,             Integer
  end

end

__loading_end(__FILE__)
