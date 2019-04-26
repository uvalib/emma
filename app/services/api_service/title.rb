# app/services/api_service/title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  module Title

    include Common

    # @type [Hash{Symbol=>String}]
    TITLE_SEND_MESSAGE = {

      # TODO: e.g.:
      no_items:      'There were no items to request',
      failed:        'Unable to request items right now',

    }.reverse_merge(API_SEND_MESSAGE).freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    TITLE_SEND_RESPONSE = {

      # TODO: e.g.:
      no_items:       'no items',
      failed:         nil

    }.reverse_merge(API_SEND_RESPONSE).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_title_count
    #
    # @return [Integer]
    #
    # == Usage Notes
    # This request can be made without an Authorization header.
    #
    def get_title_count(*)
      api(:get, 'titles', 'count')
      data = response&.body&.presence
      data.to_i
    end

    # get_title
    #
    # @param [String] bookshareId
    #
    # @return [ApiTitleMetadataDetail]
    #
    # == Usage Notes
    # This request can be made without an Authorization header.
    #
    def get_title(bookshareId:)
      api(:get, 'titles', bookshareId)
      data = response&.body&.presence
      ApiTitleMetadataDetail.new(data, error: @exception)
    end

    # download_title
    #
    # @param [String]     bookshareId
    # @param [FormatType] format
    # @param [Hash, nil]  opt
    #
    # @option opt [String] :forUser
    #
    # @return [ApiStatusModel]
    #
    def download_title(bookshareId:, format:, **opt)
      api(:get, 'titles', bookshareId, format, **opt)
      data = response&.body&.presence
      ApiStatusModel.new(data, error: @exception)
    end

    # get_titles
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]                :title
    # @option opt [String]                :author
    # @option opt [String]                :narrator
    # @option opt [String]                :composer
    # @option opt [String]                :keyword
    # @option opt [String]                :isbn
    # @option opt [String, Array<String>] :categories
    # @option opt [String]                :language
    # @option opt [String]                :country
    # @option opt [FormatType]            :format
    # @option opt [NarratorType]          :narratorType
    # @option opt [BrailleType]           :brailleType
    # @option opt [Integer]               :readingAge
    # @option opt [String]                :externalIdentifierCode
    # @option opt [IsoDuration]           :maxDuration
    # @option opt [TitleContentType]      :titleContentType
    # @option opt [String]                :start
    # @option opt [Integer]               :limit
    # @option opt [SortOrder]             :sortOrder
    # @option opt [Direction]             :direction
    #
    # @return [ApiTitleMetadataSummaryList]
    #
    # == Usage Notes
    # This request can be made without an Authorization header.
    #
    def get_titles(**opt)
      api(:get, 'titles', opt)
      data = response&.body&.presence
      ApiTitleMetadataSummaryList.new(data, error: @exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_categories
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]  :start
    # @option opt [Integer] :limit    Default: 100
    #
    # @return [ApiCategoriesList]
    #
    # == Usage Notes
    # This request can be made without an Authorization header.
    #
    def get_categories(**opt)
      api(:get, 'categories', opt)
      data = response&.body&.presence
      ApiCategoriesList.new(data, error: @exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_catalog
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]    :country
    # @option opt [String]    :start
    # @option opt [Integer]   :limit        Default: 10
    # @option opt [SortOrder] :sortOrder    Default: 'title'
    # @option opt [Direction] :direction    Default: 'asc'
    #
    # @return [ApiTitleMetadataCompleteList]
    #
    def get_catalog(**opt)
      api(:get, 'catalog', opt)
      data = response&.body&.presence
      ApiTitleMetadataCompleteList.new(data, error: @exception)
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
      response_table = TITLE_SEND_RESPONSE
      message_table  = TITLE_SEND_MESSAGE
      message = request_error_message(method, response_table, message_table)
      raise Api::TitleError, message
    end

  end

end

__loading_end(__FILE__)
