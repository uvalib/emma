# app/services/api_service/periodicals.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Periodicals
#
# == Usage Notes
#
# === From API section 2.2 (Periodicals):
# A periodical represents a magazine or newspaper, each of which can have
# multiple editions/issues. The editions/issues are available to users in the
# same way as titles, based on characteristics of the user and the
# periodical, and in formats that will be specified in the response.
#
# noinspection RubyParameterNamingConvention
module ApiService::Periodicals

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/periodicals
  #
  # == 2.2.1. Search for periodicals
  # Search for Bookshare periodicals.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]              :title
  # @option opt [String]              :issn
  # @option opt [IsoLanguage]         :language
  # @option opt [String]              :start
  # @option opt [Integer]             :limit        Default: 10
  # @option opt [PeriodicalSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]           :direction    Default: 'asc'
  #
  # @return [ApiPeriodicalSeriesMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-search
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_periodicals(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'periodicals', **opt)
    ApiPeriodicalSeriesMetadataSummaryList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          title:      String,
          issn:       String,
          language:   IsoLanguage,
          start:      String,
          limit:      Integer,
          sortOrder:  PeriodicalSortOrder,
          direction:  Direction,
        },
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_periodical-search'
      }
    end

  # == GET /v2/periodicals/{seriesId}
  #
  # == 2.2.3. Get periodical series metadata
  # Get metadata for the specified Bookshare periodical.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [ApiPeriodicalSeriesMetadataSummary]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-series-metadata
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_periodical(seriesId:, **opt)
    api(:get, 'periodicals', seriesId, **opt)
    ApiPeriodicalSeriesMetadataSummary.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
        },
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_periodical-series-metadata'
      }
    end

  # == GET /v2/periodicals/{seriesId}/editions
  #
  # == 2.2.2. Get periodical editions
  # Get a list of editions for the specified Bookshare periodical.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [Integer]          :limit       Default: 10
  # @option opt [EditionSortOrder] :sortOrder   Default: 'editionName'
  # @option opt [Direction]        :direction   Default: 'asc'
  #
  # @return [ApiPeriodicalEditionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-editions
  #
  def get_periodical_editions(seriesId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'periodicals', seriesId, 'editions', **opt)
    ApiPeriodicalEditionList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
        },
        optional: {
          limit:      Integer,
          sortOrder:  EditionSortOrder,
          direction:  Direction,
        },
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_periodical-editions'
      }
    end

  # == GET /v2/periodicals/{seriesId}/editions/{editionId}
  # Get the metadata of an existing periodical edition.
  #
  # @param [String] seriesId
  # @param [String] editionId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Api::PeriodicalEdition]
  # @return [nil]
  #
  # NOTE: This is not a real Bookshare API call.
  #
  def get_periodical_edition(seriesId:, editionId:, **opt)
    opt = opt.merge(seriesId: seriesId, limit: :max)
    periodical = get_periodical_editions(**opt)
    periodical.periodicalEditions.find { |pe| editionId == pe.editionId }
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
          editionId:  String,
        },
        reference_id: nil,
      }
    end

  # == GET /v2/periodicals/{seriesId}/editions/{editionId}/{format}
  #
  # == 2.2.4. Download a periodical edition
  # Download an artifact of the specified edition of a Bookshare periodical.
  #
  # @param [String]     seriesId
  # @param [String]     editionId
  # @param [FormatType] format
  # @param [Hash]       opt           Passed to #api.
  #
  # @option opt [String] :forUser
  #
  # @return [ApiStatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-download
  #
  def download_periodical_edition(seriesId:, editionId:, format:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'periodicals', seriesId, 'editions', editionId, format, **opt)
    ApiStatusModel.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
          editionId:  String,
          format:     FormatType,
        },
        optional: {
          forUser:    String,
        },
        reference_id: '_periodical-download'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myPeriodicals
  #
  # == 2.2.5. Get my periodical subscriptions
  # Get the list of periodical subscriptions for the authenticated user.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [ApiPeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myperiodicals
  #
  def get_my_periodicals(**opt)
    api(:get, 'myPeriodicals', **opt)
    ApiPeriodicalSubscriptionList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_get-myperiodicals'
      }
    end

  # == POST /v2/myPeriodicals
  #
  # == 2.2.6. Subscribe to a periodical series
  # Create a periodical subscription for the authenticated user.
  #
  # @param [String]               seriesId
  # @param [PeriodicalFormatType] format
  # @param [Hash]                 opt       Passed to #api.
  #
  # @return [ApiPeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_subscribe-myperiodicals
  #
  def subscribe_my_periodical(seriesId:, format:, **opt)
    opt = opt.merge(seriesId: seriesId, format: format)
    api(:post, 'myPeriodicals', **opt)
    ApiPeriodicalSubscriptionList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
          format:     PeriodicalFormatType,
        },
        reference_id: '_subscribe-myperiodicals'
      }
    end

  # == DELETE /v2/myPeriodicals/{seriesId}
  #
  # == 2.2.7. Unsubscribe from a periodical series
  # Remove a periodical subscription for the authenticated user.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [ApiPeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_unsubscribe-myperiodicals
  #
  def unsubscribe_my_periodical(seriesId:, **opt)
    api(:delete, 'myPeriodicals', seriesId, **opt)
    ApiPeriodicalSubscriptionList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
        },
        reference_id: '_unsubscribe-myperiodicals'
      }
    end

end

__loading_end(__FILE__)
