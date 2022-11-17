# app/services/bookshare_service/request/collection_periodicals.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::CollectionPeriodicals
#
# == Usage Notes
#
# === From Collection Management API 2.2 (Collection Assistant - Periodicals):
# Administrative users have resources available that will let them manage
# periodical series and editions.  These are similar in function to the title
# resources, but with differences related to the series nature of periodicals.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::CollectionPeriodicals

  include BookshareService::Common
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == PUT /v2/periodicals/(seriesId)
  #
  # == 2.2.1. Update periodical series metadata
  # Update the series metadata for an existing Bookshare periodical.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String]                          :title
  # @option opt [String]                          :issn
  # @option opt [String]                          :description
  # @option opt [String]                          :publisher
  # @option opt [String]                          :externalCategoryCode
  # @option opt [String, Array<String>]           :categories
  # @option opt [IsoLanguage, Array<IsoLanguage>] :languages
  # @option opt [BsSeriesType]                    :seriesType
  # @option opt [String, Array<String>]           :countries
  #
  # @return [Bs::Message::PeriodicalSeriesMetadataSummary]
  #
  # @see https://apidocs.bookshare.org/catalog/index.html#_periodical-update
  #
  def update_periodical(seriesId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'periodicals', seriesId, **opt)
    api_return(Bs::Message::PeriodicalSeriesMetadataSummary)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:             String,
        },
        optional: {
          title:                String,
          issn:                 String,
          description:          String,
          publisher:            String,
          externalCategoryCode: String,
          categories:           String,
          languages:            IsoLanguage,
          seriesType:           BsSeriesType,
          countries:            String,
        },
        multi:                  %i[categories languages countries],
        reference_page:         'catalog',
        reference_id:           '_periodical-update'
      }
    end

  # == PUT /v2/periodicals/(seriesId)/editions/(editionId)
  #
  # == 2.2.2. Update periodical edition metadata
  # Update the metadata of an existing periodical edition.
  #
  # @param [String] seriesId
  # @param [String] editionId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String] :editionName
  # @option opt [IsoDay] :publicationDate
  # @option opt [IsoDay] :expirationDate
  #
  # @return [Bs::Message::PeriodicalEdition]
  #
  # @see https://apidocs.bookshare.org/catalog/index.html#_put-periodical-edition-edit-metadata
  #
  def update_periodical_edition(seriesId:, editionId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'periodicals', seriesId, 'editions', editionId, **opt)
    api_return(Bs::Message::PeriodicalEdition)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:        String,
          editionId:       String,
        },
        optional: {
          editionName:     String,
          publicationDate: IsoDay,
          expirationDate:  IsoDay,
        },
        reference_page:    'catalog',
        reference_id:      '_put-periodical-edition-edit-metadata'
      }
    end

  # == DELETE /v2/periodicals/(seriesId)/editions/(editionId)
  #
  # == 2.2.3. Withdraw a periodical edition
  # Withdraw a periodical edition.
  #
  # @param [String] seriesId
  # @param [String] editionId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String] :editionName
  # @option opt [IsoDay] :publicationDate
  # @option opt [IsoDay] :expirationDate
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/catalog/index.html#_withdraw-periodical-edition
  #
  def remove_periodical_edition(seriesId:, editionId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:delete, 'periodicals', seriesId, 'editions', editionId, **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:     String,
          editionId:    String,
        },
        reference_page: 'catalog',
        reference_id:   '_withdraw-periodical-edition'
      }
    end

end

__loading_end(__FILE__)
