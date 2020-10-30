# app/services/bookshare_service/request/collection_periodicals.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::CollectionPeriodicals
#
# == Usage Notes
#
# === From API section 2.9 (Collection Assistant - Periodicals):
# Administrative users have resources available that will let them manage
# periodical series and editions.  These are similar in function to the title
# resources, but with differences related to the series nature of periodicals.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::CollectionPeriodicals

  include BookshareService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == PUT /v2/periodicals/{seriesId}
  #
  # == 2.9.1. Update periodical series metadata
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
  #
  # @return [Bs::Message::PeriodicalSeriesMetadataSummary]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-update
  #
  #--
  # noinspection LongLine
  #++
  def update_periodical(seriesId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'periodicals', seriesId, **opt)
    Bs::Message::PeriodicalSeriesMetadataSummary.new(response, error: exception)
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
        },
        multi:                  %i[categories languages],
        reference_id:           '_periodical-update'
      }
    end

  # == PUT /v2/periodicals/{seriesId}/editions/{editionId}
  #
  # == 2.9.2. Update periodical edition metadata
  # Update the metadata of an existing periodical edition.
  #
  # @param [String] seriesId
  # @param [String] editionId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String] :editionName
  # @option opt [IsoDay] :publicationDate
  #
  # @return [Bs::Message::PeriodicalEdition]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-periodical-edition-edit-metadata
  #
  def update_periodical_edition(seriesId:, editionId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'periodicals', seriesId, 'editions', editionId, **opt)
    Bs::Message::PeriodicalEdition.new(response, error: exception)
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
        },
        reference_id:      '_put-periodical-edition-edit-metadata'
      }
    end

end

__loading_end(__FILE__)
