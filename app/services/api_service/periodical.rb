# app/services/api_service/periodical.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  module Periodical

    include Common

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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_periodicals
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]    :title
    # @option opt [String]    :issn
    # @option opt [String]    :language
    # @option opt [String]    :start
    # @option opt [Integer]   :limit        Default: 10
    # @option opt [SortOrder] :sortOrder    Default: 'title'
    # @option opt [Direction] :direction    Default: 'asc'
    #
    # @return [ApiPeriodicalSeriesMetadataSummaryList]
    #
    # == Usage Notes
    # This request can be made without an Authorization header.
    #
    def get_periodicals(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'periodicals', opt)
      data = response&.body&.presence
      ApiPeriodicalSeriesMetadataSummaryList.new(data, error: @exception)
    end

    # get_periodical
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
      data = response&.body&.presence
      ApiPeriodicalSeriesMetadataSummary.new(data, error: @exception)
    end

    # update_periodical
    #
    # @param [String]    seriesId
    # @param [Hash, nil] opt
    #
    # @option opt [String]                :title
    # @option opt [String]                :issn
    # @option opt [String]                :description
    # @option opt [String]                :publisher
    # @option opt [String]                :externalCategoryCode
    # @option opt [String, Array<String>] :categories
    # @option opt [String, Array<String>] :languages
    #
    # @return [ApiPeriodicalSeriesMetadataSummary]
    #
    def update_periodical(seriesId:, **opt)
      validate_parameters(__method__, opt)
      api(:put, 'periodicals', seriesId, opt)
      data = response&.body&.presence
      ApiPeriodicalSeriesMetadataSummary.new(data, error: @exception)
    end

    # get_periodical_editions
    #
    # @param [String]    seriesId
    # @param [Hash, nil] opt
    #
    # @option opt [Integer]   :limit        Default: 10
    # @option opt [SortOrder] :sortOrder    Default: 'editionName'
    # @option opt [Direction] :direction    Default: 'asc'
    #
    # @return [ApiPeriodicalEditionList]
    #
    def get_periodical_editions(seriesId:, **opt)
      validate_parameters(__method__, opt)
      api(:get, 'periodicals', seriesId, 'editions', opt)
      data = response&.body&.presence
      ApiPeriodicalEditionList.new(data, error: @exception)
    end

    # update_periodical_edition
    #
    # @param [String]    seriesId
    # @param [String]    editionId
    # @param [Hash, nil] opt
    #
    # @option opt [String] :editionName
    # @option opt [IsoDay] :publicationDate
    #
    # @return [ApiPeriodicalEdition]
    #
    def update_periodical_edition(seriesId:, editionId:, **opt)
      validate_parameters(__method__, opt)
      api(:put, 'periodicals', seriesId, 'editions', editionId, opt)
      data = response&.body&.presence
      ApiPeriodicalEdition.new(data, error: @exception)
    end

    # download_periodical_edition
    #
    # @param [String]     seriesId
    # @param [String]     editionId
    # @param [FormatType] format
    # @param [Hash, nil]  opt
    #
    # @option opt [String] :forUser
    #
    # @return [ApiStatusModel]
    #
    def download_periodical_edition(seriesId:, editionId:, format:, **opt)
      validate_parameters(__method__, opt)
      api(:get, 'periodicals', seriesId, 'editions', editionId, format, opt)
      data = response&.body&.presence
      ApiStatusModel.new(data, error: @exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # raise_exception
    #
    # @param [Symbol, String] method  For log messages.
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

end

__loading_end(__FILE__)
