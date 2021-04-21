# app/services/bookshare_service/request/collection_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::CollectionTitles
#
# == Usage Notes
#
# === From Collection Management API 2.1 (Collection Assistant - Titles):
# Administrative users have resources available that will let them manage the
# collection, either by adding or removing titles, or by manipulating their
# metadata.  This could include withdrawing live titles, publishing pending
# titles, or reviewing proofread scans.  Collection Assistants can perform
# these functions, only restricted to the titles that are associated with their
# site.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::CollectionTitles

  include BookshareService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/catalog
  #
  # == 2.1.4. Search for titles across the catalog
  # For allowed roles, you can ask for titles that might not be visible to
  # regular users, such as those that were once in the collection, but have
  # since been removed. This allows administrators to manage the wider
  # collection of titles.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]             :country
  # @option opt [String]             :isbn
  # @option opt [BsTitleStatus]      :titleStatus
  # @option opt [IsoDate]            :startUpdatedDate
  # @option opt [IsoDate]            :endUpdatedDate
  # @option opt [String]             :start
  # @option opt [Integer]            :limit        Default: 10
  # @option opt [BsCatalogSortOrder] :sortOrder    Default: 'title'
  # @option opt [BsSortDirection]    :direction    Default: 'asc'
  #
  # @return [Bs::Message::TitleMetadataCompleteList]
  #
  # @see https://apidocs.bookshare.org/catalog/index.html#_catalog-search
  #
  def get_catalog(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'catalog', **opt)
    Bs::Message::TitleMetadataCompleteList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          country:          String,
          isbn:             String,
          titleStatus:      BsTitleStatus,
          startUpdatedDate: IsoDate,
          endUpdatedDate:   IsoDate,
          start:            String,
          limit:            Integer,
          sortOrder:        BsCatalogSortOrder,
          direction:        BsSortDirection,
        },
        reference_page:     'catalog',
        reference_id:       '_catalog-search'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == POST /v2/titles
  #
  # == 2.1.1. Submit metadata for new title
  # Submit metadata for a new title to the collection.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                    :title                  *REQUIRED*
  # @option opt [String]                    :subtitle
  # @option opt [String]                    :isbn13                 *REQUIRED*
  # @option opt [String, Array<String>]     :authors                *REQUIRED*
  # @option opt [String, Array<String>]     :abridgers
  # @option opt [String, Array<String>]     :adapters
  # @option opt [String, Array<String>]     :arrangers
  # @option opt [String, Array<String>]     :composers
  # @option opt [String, Array<String>]     :coWriters
  # @option opt [String, Array<String>]     :editors
  # @option opt [String, Array<String>]     :epilogueBys
  # @option opt [String, Array<String>]     :forewardBys
  # @option opt [String, Array<String>]     :introductionBys
  # @option opt [String, Array<String>]     :lyricists
  # @option opt [String, Array<String>]     :transcribers
  # @option opt [String, Array<String>]     :translators
  # @option opt [String]                    :synopsis               *REQUIRED*
  # @option opt [String]                    :seriesTitle
  # @option opt [String]                    :seriesSubtitle
  # @option opt [String]                    :seriesNumber
  # @option opt [String]                    :copyrightHolder
  # @option opt [Integer]                   :copyrightDate
  # @option opt [String]                    :edition
  # @option opt [Integer]                   :readingAgeMinimum
  # @option opt [Integer]                   :readingAgeMaximum
  # @option opt [Boolean]                   :adultContent
  # @option opt [Boolean]                   :allowRecommend
  # @option opt [Integer]                   :numPages
  # @option opt [String]                    :publisher
  # @option opt [Array<BsCategoryType>]     :categories             *REQUIRED*
  # @option opt [String, Array<String>]     :countries              *REQUIRED*
  # @option opt [String, Array<String>]     :languages              *REQUIRED*
  # @option opt [String, Array<String>]     :grades
  # @option opt [Array<BsContentWarning>]   :contentWarnings
  # @option opt [String, Array<String>]     :relatedIsbns
  # @option opt [BsRightsType]              :usageRestriction       *REQUIRED*
  # @option opt [String]                    :externalCategoryCode
  # @option opt [BsMusicScoreType]          :musicScoreType
  # @option opt [Boolean]                   :hasChordSymbols
  # @option opt [String]                    :instruments
  # @option opt [String]                    :key
  # @option opt [String]                    :movementNumber
  # @option opt [String]                    :movementTitle
  # @option opt [String]                    :opus
  # @option opt [String]                    :vocalParts
  # @option opt [String]                    :notes
  # @option opt [Boolean]                   :marrakeshEligible
  # @option opt [String, Array<String>]     :userAvailabilities
  # @option opt [Boolean]                   :availableToDemo
  # @option opt [Boolean]                   :availableWorldwide
  # @option opt [String, Array<String>]     :states
  # @option opt [BsTitleContentType]        :contentType
  # @option opt [String]                    :comments
  # @option opt [Boolean]                   :hasEmbeddedImageDescriptions
  # @option opt [BsScanQuality]             :quality
  # @option opt [String]                    :originCountry
  # @option opt [String]                    :productIdentifier
  # @option opt [String]                    :seriesId
  # @option opt [BsExternalFormatType]      :externalFormat         *REQUIRED*
  # @option opt [BsLexileCode]              :lexileCode
  # @option opt [String]                    :lexileNumber
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/catalog/index.html#_title-submit
  #
  def submit_catalog_title(**opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'titles', **opt)
    Bs::Message::StatusModel.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          title:                        String,
          isbn13:                       String,
          authors:                      String,
          synopsis:                     String,
          categories:                   BsCategoryType,
          countries:                    String,
          languages:                    String,
          usageRestriction:             BsRightsType,
          contentType:                  BsTitleContentType,
          externalFormat:               BsExternalFormatType,
        },
        optional: {
          subtitle:                     String,
          abridgers:                    String,
          adapters:                     String,
          arrangers:                    String,
          composers:                    String,
          coWriters:                    String,
          editors:                      String,
          epilogueBys:                  String,
          forewardBys:                  String,
          introductionBys:              String,
          lyricists:                    String,
          transcribers:                 String,
          translators:                  String,
          seriesTitle:                  String,
          seriesSubtitle:               String,
          seriesNumber:                 String,
          copyrightHolder:              String,
          copyrightDate:                Integer,
          edition:                      String,
          readingAgeMinimum:            Integer,
          readingAgeMaximum:            Integer,
          adultContent:                 Boolean,
          allowRecommend:               Boolean,
          numPages:                     Integer,
          publisher:                    String,
          grades:                       String,
          contentWarnings:              BsContentWarning,
          relatedIsbns:                 String,
          externalCategoryCode:         String,
          musicScoreType:               BsMusicScoreType,
          hasChordSymbols:              Boolean,
          instruments:                  String,
          key:                          String,
          movementNumber:               String,
          movementTitle:                String,
          opus:                         String,
          vocalParts:                   String,
          notes:                        String,
          marrakeshEligible:            Boolean,
          userAvailabilities:           String,
          availableToDemo:              Boolean,
          availableWorldwide:           Boolean,
          states:                       String,
          comments:                     String,
          hasEmbeddedImageDescriptions: Boolean,
          quality:                      BsScanQuality,
          originCountry:                String,
          productIdentifier:            String,
          seriesId:                     String,
          lexileCode:                   BsLexileCode,
          lexileNumber:                 String,
        },
        multi: %i[
          authors
          abridgers
          adapters
          arrangers
          composers
          coWriters
          editors
          epilogueBys
          forewardBys
          introductionBys
          lyricists
          transcribers
          translators
          categories
          countries
          languages
          grades
          contentWarnings
          relatedIsbns
          userAvailabilities
          states
        ],
        reference_page: 'catalog',
        reference_id:   '_title-submit'
      }
    end

  # == PUT /v2/titles/(bookshareId)
  #
  # == 2.1.2. Update title metadata
  # Update a title’s metadata. This includes title, author, ISBN and other
  # properties. This submits a request that will be processed at some point in
  # the future. The title history event list will include an entry reflecting
  # this request and showing when it was applied.
  #
  # @param [String] bookshareId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String]                    :title
  # @option opt [String]                    :subtitle
  # @option opt [String]                    :isbn13
  # @option opt [String, Array<String>]     :authors
  # @option opt [String, Array<String>]     :abridgers
  # @option opt [String, Array<String>]     :adapters
  # @option opt [String, Array<String>]     :arrangers
  # @option opt [String, Array<String>]     :composers
  # @option opt [String, Array<String>]     :coWriters
  # @option opt [String, Array<String>]     :editors
  # @option opt [String, Array<String>]     :epilogueBys
  # @option opt [String, Array<String>]     :forewardBys
  # @option opt [String, Array<String>]     :introductionBys
  # @option opt [String, Array<String>]     :lyricists
  # @option opt [String, Array<String>]     :transcribers
  # @option opt [String, Array<String>]     :translators
  # @option opt [String]                    :synopsis
  # @option opt [String]                    :seriesTitle
  # @option opt [String]                    :seriesSubtitle
  # @option opt [String]                    :seriesNumber
  # @option opt [String]                    :copyrightHolder
  # @option opt [Integer]                   :copyrightDate
  # @option opt [String]                    :edition
  # @option opt [Integer]                   :readingAgeMinimum
  # @option opt [Integer]                   :readingAgeMaximum
  # @option opt [Boolean]                   :adultContent
  # @option opt [Boolean]                   :allowRecommend
  # @option opt [Integer]                   :numPages
  # @option opt [String]                    :publisher
  # @option opt [Array<BsCategoryType>]     :categories
  # @option opt [String, Array<String>]     :bisacCategories
  # @option opt [String, Array<String>]     :countries
  # @option opt [String, Array<String>]     :languages
  # @option opt [String, Array<String>]     :grades
  # @option opt [Array<BsContentWarning>]   :contentWarnings
  # @option opt [String, Array<String>]     :relatedIsbns
  # @option opt [BsRightsType]              :usageRestriction
  # @option opt [String]                    :externalCategoryCode
  # @option opt [BsMusicScoreType]          :musicScoreType
  # @option opt [Boolean]                   :hasChordSymbols
  # @option opt [String]                    :instruments
  # @option opt [String]                    :key
  # @option opt [String]                    :movementNumber
  # @option opt [String]                    :movementTitle
  # @option opt [String]                    :opus
  # @option opt [String]                    :vocalParts
  # @option opt [String]                    :notes
  # @option opt [Boolean]                   :marrakeshEligible
  # @option opt [String, Array<String>]     :userAvailabilities
  # @option opt [Boolean]                   :availableToDemo
  # @option opt [Boolean]                   :availableWorldwide
  # @option opt [String, Array<String>]     :states
  # @option opt [String]                    :comments
  # @option opt [Boolean]                   :hasEmbeddedImageDescriptions
  # @option opt [BsScanQuality]             :quality
  # @option opt [String]                    :originCountry
  # @option opt [String]                    :productIdentifier
  # @option opt [String]                    :seriesId
  # @option opt [BsLexileCode]              :lexileCode
  # @option opt [String]                    :lexileNumber
  # @option opt [Boolean]                   :nimacRestricted
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/catalog/index.html#_title-metadata-update
  #
  def update_catalog_title(bookshareId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'titles', bookshareId, **opt)
    Bs::Message::StatusModel.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId:                  String,
        },
        optional: {
          title:                        String,
          subtitle:                     String,
          isbn13:                       String,
          authors:                      String,
          abridgers:                    String,
          adapters:                     String,
          arrangers:                    String,
          composers:                    String,
          coWriters:                    String,
          editors:                      String,
          epilogueBys:                  String,
          forewardBys:                  String,
          introductionBys:              String,
          lyricists:                    String,
          transcribers:                 String,
          translators:                  String,
          synopsis:                     String,
          seriesTitle:                  String,
          seriesSubtitle:               String,
          seriesNumber:                 String,
          copyrightHolder:              String,
          copyrightDate:                Integer,
          edition:                      String,
          readingAgeMinimum:            Integer,
          readingAgeMaximum:            Integer,
          adultContent:                 Boolean,
          allowRecommend:               Boolean,
          numPages:                     Integer,
          publisher:                    String,
          categories:                   BsCategoryType,
          bisacCategories:              String,
          countries:                    String,
          languages:                    String,
          grades:                       String,
          contentWarnings:              BsContentWarning,
          relatedIsbns:                 String,
          usageRestriction:             BsRightsType,
          externalCategoryCode:         String,
          musicScoreType:               BsMusicScoreType,
          hasChordSymbols:              Boolean,
          instruments:                  String,
          key:                          String,
          movementNumber:               String,
          movementTitle:                String,
          opus:                         String,
          vocalParts:                   String,
          notes:                        String,
          marrakeshEligible:            Boolean,
          userAvailabilities:           String,
          availableToDemo:              Boolean,
          availableWorldwide:           Boolean,
          states:                       String,
          comments:                     String,
          hasEmbeddedImageDescriptions: Boolean,
          quality:                      BsScanQuality,
          originCountry:                String,
          productIdentifier:            String,
          seriesId:                     String,
          lexileCode:                   BsLexileCode,
          lexileNumber:                 String,
          nimacRestricted:              Boolean,
        },
        multi: %i[
            authors
            abridgers
            adapters
            arrangers
            composers
            coWriters
            editors
            epilogueBys
            forewardBys
            introductionBys
            lyricists
            transcribers
            translators
            categories
            bisacCategories
            countries
            languages
            grades
            contentWarnings
            relatedIsbns
            userAvailabilities
            states
          ],
        reference_page: 'catalog',
        reference_id:   '_title-metadata-update'
      }
    end

  # == GET /v2/titles/(bookshareId)/history
  #
  # == 2.1.3. Get a list of title history events
  #
  # @param [String] bookshareId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String] :start
  #
  # @return [Bs::Message::TitleHistoryEventResourceList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-title-history-events
  #
  def get_title_history(bookshareId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', bookshareId, 'history', **opt)
    Bs::Message::TitleHistoryEventResourceList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId:  String,
        },
        reference_page: 'catalog',
        reference_id:   '_get-title-history-events'
      }
    end

end

__loading_end(__FILE__)
