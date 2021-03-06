# app/records/bs/message/title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::TitleMetadataSummary
#
# @attr [Array<Bs::Record::Name>]        arrangers         *deprecated*
# @attr [Array<Bs::Record::Name>]        authors           *deprecated*
# @attr [Boolean]                        available
# @attr [String]                         bookshareId
# @attr [Array<Bs::Record::Category>]    categories
# @attr [Array<Bs::Record::Name>]        composers         *deprecated*
# @attr [Array<BsContentWarning>]        contentWarnings
# @attr [Array<Bs::Record::Contributor>] contributors
# @attr [IsoYear]                        copyrightDate
# @attr [Array<Bs::Record::Format>]      formats
# @attr [String]                         instruments
# @attr [String]                         isbn13
# @attr [Array<String>]                  languages
# @attr [Array<Bs::Record::Link>]        links
# @attr [Array<Bs::Record::Name>]        lyricists         *deprecated*
# @attr [IsoDate]                        publishDate
# @attr [Integer]                        readingAgeMaximum
# @attr [Integer]                        readingAgeMinimum
# @attr [String]                         seriesNumber
# @attr [String]                         seriesTitle
# @attr [String]                         site
# @attr [String]                         subtitle
# @attr [String]                         synopsis
# @attr [String]                         title
# @attr [String]                         titleContentType
# @attr [Array<Bs::Record::Name>]        translators       *deprecated*
# @attr [String]                         vocalParts
#
# @see https://apidocs.bookshare.org/reference/index.html#_title_metadata_summary
#
# @see Bs::Record::TitleMetadataSummary (duplicate schema)
#
class Bs::Message::TitleMetadataSummary < Bs::Api::Message

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  #--
  # noinspection DuplicatedCode
  #++
  schema do
    has_many  :arrangers,         Bs::Record::Name          # NOTE: deprecated
    has_many  :authors,           Bs::Record::Name          # NOTE: deprecated
    has_one   :available,         Boolean
    has_one   :bookshareId
    has_many  :categories,        Bs::Record::Category
    has_many  :composers,         Bs::Record::Name          # NOTE: deprecated
    has_many  :contentWarnings,   BsContentWarning
    has_many  :contributors,      Bs::Record::Contributor
    has_one   :copyrightDate,     IsoYear
    has_many  :formats,           Bs::Record::Format
    has_one   :instruments
    has_one   :isbn13
    has_many  :languages
    has_many  :links,             Bs::Record::Link
    has_many  :lyricists,         Bs::Record::Name          # NOTE: deprecated
    has_one   :publishDate,       IsoDate
    has_one   :readingAgeMaximum, Integer
    has_one   :readingAgeMinimum, Integer
    has_one   :seriesNumber
    has_one   :seriesTitle
    has_one   :site
    has_one   :subtitle
    has_one   :synopsis
    has_one   :title
    has_one   :titleContentType
    has_many  :translators,       Bs::Record::Name          # NOTE: deprecated
    has_one   :vocalParts
  end

end

__loading_end(__FILE__)
