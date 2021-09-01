# app/records/bs/record/reading_list_title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::ReadingListTitle
#
# @attr [Array<BsAllowsType>]       allows
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many  :allows,           BsAllowsType
    has_many  :authors,          Bs::Record::Name           # NOTE: deprecated
    has_one   :available,        Boolean
    has_one   :award
    has_one   :bookshareId
    has_one   :category
    has_many  :composers,        Bs::Record::Name           # NOTE: deprecated
    has_one   :copyrightDate,    IsoYear
    has_one   :dateAdded,        IsoDate
    has_many  :formats,          Bs::Record::Format
    has_one   :instruments
    has_one   :isbn13
    has_many  :languages
    has_many  :links,            Bs::Record::Link
    has_one   :month,            Integer
    has_one   :publishDate,      IsoDate
    has_one   :ranking,          Integer
    has_one   :seriesNumber
    has_one   :seriesTitle
    has_one   :subtitle
    has_one   :synopsis
    has_one   :title
    has_one   :titleContentType
    has_one   :vocalParts
    has_one   :year,             Integer
  end

end

__loading_end(__FILE__)
