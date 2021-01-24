# app/records/bs/record/title_metadata_complete.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::TitleMetadataComplete
#
# @attr [Boolean]                             adultContent
# @attr [Boolean]                             allowRecommend
# @attr [Array<AllowsType>]                   allows
# @attr [Array<Bs::Record::Name>]             arrangers            *deprecated*
# @attr [Array<Bs::Record::ArtifactMetadata>] artifacts
# @attr [Array<Bs::Record::Name>]             authors              *deprecated*
# @attr [Boolean]                             available
# @attr [String]                              bookshareId
# @attr [Array<Bs::Record::Category>]         categories
# @attr [Array<Bs::Record::Name>]             composers            *deprecated*
# @attr [Array<ContentWarning>]               contentWarnings
# @attr [Array<Bs::Record::Contributor>]      contributors
# @attr [String]                              copyright            *deprecated*
# @attr [IsoYear]                             copyrightDate
# @attr [String]                              copyrightHolder
# @attr [Array<String>]                       countries
# @attr [Integer]                             dtbookSize
# @attr [String]                              edition
# @attr [String]                              externalCategoryCode
# @attr [Array<Bs::Record::Format>]           externalFormats
# @attr [Array<Bs::Record::Format>]           formats
# @attr [Array<Bs::Record::Grade>]            grades
# @attr [String]                              hasChordSymbols      *Boolean*
# @attr [String]                              instruments
# @attr [String]                              isbn13
# @attr [String]                              key
# @attr [Array<String>]                       languages
# @attr [IsoDate]                             lastUpdated
# @attr [Array<Bs::Record::Link>]             links
# @attr [Array<Bs::Record::Name>]             lyricists            *deprecated*
# @attr [Boolean]                             marrakeshAvailable
# @attr [Boolean]                             marrakeshPODException
# @attr [String]                              movementNumber
# @attr [String]                              movementTitle
# @attr [String]                              musicLayout
# @attr [String]                              musicScoreType
# @attr [String]                              notes
# @attr [Integer]                             numImages
# @attr [Integer]                             numPages
# @attr [String]                              opus
# @attr [String]                              proofreader
# @attr [IsoDate]                             publishDate
# @attr [String]                              publisher
# @attr [Integer]                             readingAgeMaximum
# @attr [Integer]                             readingAgeMinimum
# @attr [Array<String>]                       relatedIsbns
# @attr [String]                              replacementId
# @attr [String]                              seriesNumber
# @attr [String]                              seriesSubtitle
# @attr [String]                              seriesTitle
# @attr [String]                              site
# @attr [String]                              submitter
# @attr [String]                              subtitle
# @attr [String]                              synopsis
# @attr [String]                              title
# @attr [String]                              titleContentType
# @attr [String]                              titleSource
# @attr [Array<Bs::Record::Name>]             translators          *deprecated*
# @attr [Bs::Record::UsageRestriction]        usageRestriction
# @attr [String]                              vocalParts
# @attr [IsoDate]                             withdrawalDate
#
# @see https://apidocs.bookshare.org/catalog/index.html#_title_metadata_complete
#
# == Implementation Notes
# Similar to Bs::Message::TitleMetadataDetail, but adds these fields:
#   :dtbookSize
#   :lastUpdated
#   :numImages
#   :proofreader
#   :submitter
#   :titleSource
#   :withdrawalDate
#
class Bs::Record::TitleMetadataComplete < Bs::Api::Record

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  #--
  # noinspection DuplicatedCode
  #++
  schema do
    has_one   :adultContent,          Boolean
    has_one   :allowRecommend,        Boolean
    has_many  :allows,                AllowsType
    has_many  :arrangers,             Bs::Record::Name       # NOTE: deprecated
    has_many  :artifacts,             Bs::Record::ArtifactMetadata
    has_many  :authors,               Bs::Record::Name       # NOTE: deprecated
    has_one   :available,             Boolean
    has_one   :bookshareId
    has_many  :categories,            Bs::Record::Category
    has_many  :composers,             Bs::Record::Name       # NOTE: deprecated
    has_many  :contentWarnings,       ContentWarning
    has_many  :contributors,          Bs::Record::Contributor
    has_one   :copyright                                     # NOTE: deprecated
    has_one   :copyrightDate,         IsoYear
    has_one   :copyrightHolder
    has_many  :countries
    has_one   :dtbookSize,            Integer
    has_one   :edition
    has_one   :externalCategoryCode
    has_many  :externalFormats,       Bs::Record::Format
    has_many  :formats,               Bs::Record::Format
    has_many  :grades,                Bs::Record::Grade
    has_one   :hasChordSymbols,       String                 # NOTE: Boolean
    has_one   :instruments
    has_one   :isbn13
    has_one   :key
    has_many  :languages
    has_one   :lastUpdated,           IsoDate
    has_many  :links,                 Bs::Record::Link
    has_many  :lyricists,             Bs::Record::Name       # NOTE: deprecated
    has_one   :marrakeshAvailable,    Boolean
    has_one   :marrakeshPODException, Boolean
    has_one   :movementNumber
    has_one   :movementTitle
    has_one   :musicLayout
    has_one   :musicScoreType
    has_one   :notes
    has_one   :numImages,             Integer
    has_one   :numPages,              Integer
    has_one   :opus
    has_one   :proofreader
    has_one   :publishDate,           IsoDate
    has_one   :publisher
    has_one   :readingAgeMaximum,     Integer
    has_one   :readingAgeMinimum,     Integer
    has_many  :relatedIsbns
    has_one   :replacementId
    has_one   :seriesNumber
    has_one   :seriesSubtitle
    has_one   :seriesTitle
    has_one   :site
    has_one   :submitter
    has_one   :subtitle
    has_one   :synopsis
    has_one   :title
    has_one   :titleContentType
    has_one   :titleSource
    has_many  :translators,           Bs::Record::Name       # NOTE: deprecated
    has_one   :usageRestriction,      Bs::Record::UsageRestriction
    has_one   :vocalParts
    has_one   :withdrawalDate,        IsoDate
  end

end

__loading_end(__FILE__)
