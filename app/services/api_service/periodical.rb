# app/services/api_service/periodical.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Periodical
#
# == Usage Notes
#
# === According to API section 2.2 (Periodicals):
# A periodical represents a magazine or newspaper, each of which can have
# multiple editions/issues. The editions/issues are available to users in the
# same way as titles, based on characteristics of the user and the
# periodical, and in formats that will be specified in the response.
#
# noinspection RubyParameterNamingConvention
module ApiService::Periodical

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  PERIODICAL_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  PERIODICAL_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/periodicals
  # Search for Bookshare periodicals.
  #
  # @param [Hash] opt                 API URL parameters
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
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_periodicals(**opt)
    validate_parameters(__method__, opt)
    api(:get, 'periodicals', **opt)
    ApiPeriodicalSeriesMetadataSummaryList.new(response, error: exception)
  end

  # == GET /v2/periodicals/{seriesId}
  # Get metadata for the specified Bookshare periodical.
  #
  # @param [String] seriesId
  #
  # @return [ApiPeriodicalSeriesMetadataSummary]
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_periodical(seriesId:)
    api(:get, 'periodicals', seriesId)
    ApiPeriodicalSeriesMetadataSummary.new(response, error: exception)
  end

  # == PUT /v2/periodicals/{seriesId}
  # Update the series metadata for an existing Bookshare periodical.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               API URL parameters
  #
  # @option opt [String]                          :title
  # @option opt [String]                          :issn
  # @option opt [String]                          :description
  # @option opt [String]                          :publisher
  # @option opt [String]                          :externalCategoryCode
  # @option opt [String, Array<String>]           :categories
  # @option opt [IsoLanguage, Array<IsoLanguage>] :languages
  #
  # @return [ApiPeriodicalSeriesMetadataSummary]
  #
  def update_periodical(seriesId:, **opt)
    validate_parameters(__method__, opt)
    api(:put, 'periodicals', seriesId, **opt)
    ApiPeriodicalSeriesMetadataSummary.new(response, error: exception)
  end

  # == GET /v2/periodicals/{seriesId}/editions
  # Get a list of editions for the specified Bookshare periodical.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               API URL parameters
  #
  # @option opt [Integer]          :limit       Default: 10
  # @option opt [EditionSortOrder] :sortOrder   Default: 'editionName'
  # @option opt [Direction]        :direction   Default: 'asc'
  #
  # @return [ApiPeriodicalEditionList]
  #
  def get_periodical_editions(seriesId:, **opt)
    validate_parameters(__method__, opt)
    api(:get, 'periodicals', seriesId, 'editions', **opt)
    ApiPeriodicalEditionList.new(response, error: exception)
  end

  # == PUT /v2/periodicals/{seriesId}/editions/{editionId}
  # Update the metadata of an existing periodical edition.
  #
  # @param [String] seriesId
  # @param [String] editionId
  # @param [Hash]   opt               API URL parameters
  #
  # @option opt [String] :editionName
  # @option opt [IsoDay] :publicationDate
  #
  # @return [ApiPeriodicalEdition]
  #
  def update_periodical_edition(seriesId:, editionId:, **opt)
    validate_parameters(__method__, opt)
    api(:put, 'periodicals', seriesId, 'editions', editionId, **opt)
    ApiPeriodicalEdition.new(response, error: exception)
  end

  # == GET /v2/periodicals/{seriesId}/editions/{editionId}/{format}
  # Download an artifact of the specified edition of a Bookshare periodical.
  #
  # @param [String]     seriesId
  # @param [String]     editionId
  # @param [FormatType] format
  # @param [Hash]       opt           API URL parameters
  #
  # @option opt [String] :forUser
  #
  # @return [ApiStatusModel]
  #
  def download_periodical_edition(seriesId:, editionId:, format:, **opt)
    validate_parameters(__method__, opt)
    api(:get, 'periodicals', seriesId, 'editions', editionId, format, **opt)
    ApiStatusModel.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # raise_exception
  #
  # @param [Symbol, String] method    For log messages.
  #
  # This method overrides:
  # @see ApiService::Common#raise_exception
  #
  def raise_exception(method)
    response_table = PERIODICAL_SEND_RESPONSE
    message_table  = PERIODICAL_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::PeriodicalError, message
  end

end

__loading_end(__FILE__)
