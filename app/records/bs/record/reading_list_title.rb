# app/records/bs/record/reading_list_title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ReadingListTitle
#
# @attr [Array<AllowsType>]         allows
# @attr [Array<Bs::Record::Name>]   authors            *deprecated*
# @attr [Boolean]                   available
# @attr [String]                    award
# @attr [String]                    bookshareId
# @attr [String]                    category
# @attr [Array<Bs::Record::Name>]   composers          *deprecated*
# @attr [IsoYear]                   copyrightDate
# @attr [String]                    dateAdded
# @attr [Array<Bs::Record::Format>] formats
# @attr [String]                    instruments
# @attr [String]                    isbn13
# @attr [Array<String>]             languages
# @attr [Array<Bs::Record::Link>]   links
# @attr [Integer]                   month
# @attr [IsoDate]                   publishDate
# @attr [Integer]                   ranking
# @attr [String]                    seriesNumber
# @attr [String]                    seriesTitle
# @attr [String]                    subtitle
# @attr [String]                    synopsis
# @attr [String]                    title
# @attr [String]                    titleContentType
# @attr [String]                    vocalParts
# @attr [Integer]                   year
#
# @see https://apidocs.bookshare.org/reference/index.html#_reading_list_title
#
class Bs::Record::ReadingListTitle < Bs::Api::Record

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  schema do
    has_many  :allows,           AllowsType
    has_many  :authors,          Bs::Record::Name           # NOTE: deprecated
    attribute :available,        Boolean
    attribute :award,            String
    attribute :bookshareId,      String
    attribute :category,         String
    has_many  :composers,        Bs::Record::Name           # NOTE: deprecated
    attribute :copyrightDate,    IsoYear
    attribute :dateAdded,        IsoDate
    has_many  :formats,          Bs::Record::Format
    attribute :instruments,      String
    attribute :isbn13,           String
    has_many  :languages,        String
    has_many  :links,            Bs::Record::Link
    attribute :month,            Integer
    attribute :publishDate,      IsoDate
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
