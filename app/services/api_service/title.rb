# app/services/api_service/title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  # ApiService::Title
  #
  # == Usage Notes
  #
  # === According to API section 2.1 (Titles):
  # A title represents a unique entry in the Bookshare collection. They are
  # available to users based on a combination of the characteristics of the
  # user (their subscription, their address, their age, etc) and the
  # characteristics of the title (its distribution area, whether it is
  # copyrighted, etc). Users can request a metadata representation of almost
  # any title, but they can only request a file download if the user and title
  # characteristics allow, and if the requested format is available for the
  # particular title. The title metadata resource is where you will find links
  # to the specific file format resources that are available for each specific
  # title.
  #
  # noinspection RubyParameterNamingConvention
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

    # == GET /v2/titles/count
    # Get the current count of Bookshare titles.
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

    # == GET /v2/titles/:bookshareId
    # Get metadata for the specified Bookshare title.
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
      ApiTitleMetadataDetail.new(response, error: exception)
    end

    # == GET /v2/titles/:bookshareId/:format
    # Download a Bookshare title artifact.
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
      validate_parameters(__method__, opt)
      api(:get, 'titles', bookshareId, format, opt)
      ApiStatusModel.new(response, error: exception)
    end

    # == GET /v2/titles
    # Search for Bookshare titles.
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]                :title
    # @option opt [String]                :author
    # @option opt [String]                :narrator
    # @option opt [String]                :composer
    # @option opt [String]                :keyword
    # @option opt [String]                :isbn
    # @option opt [String, Array<String>] :categories # NOTE: <string>array(multi)
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
    # @option opt [TitleSortOrder]        :sortOrder
    # @option opt [Direction]             :direction
    #
    # @return [ApiTitleMetadataSummaryList]
    #
    # == Usage Notes
    # This request can be made without an Authorization header.
    #
    def get_titles(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'titles', opt)
      ApiTitleMetadataSummaryList.new(response, error: exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # == GET /v2/categories
    # Search for Bookshare categories.
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
      validate_parameters(__method__, opt)
      api(:get, 'categories', opt)
      ApiCategoriesList.new(response, error: exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # == GET /v2/catalog
    # For allowed roles, you can ask for titles that might not be visible to
    # regular users, such as those that were once in the collection, but have
    # since been removed. This allows administrators to manage the wider
    # collection of titles.
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]           :country
    # @option opt [String]           :isbn
    # @option opt [String]           :start
    # @option opt [Integer]          :limit        Default: 10
    # @option opt [CatalogSortOrder] :sortOrder    Default: 'title'
    # @option opt [Direction]        :direction    Default: 'asc'
    #
    # @return [ApiTitleMetadataCompleteList]
    #
    # == Usage Notes
    #
    # === According to API section 2.7 (Collection Assistant - Titles):
    # Administrative users can search and update the entire collection of
    # titles, not just those that are live for the public to see. This could
    # include withdrawing live titles, publishing pending titles, or reviewing
    # proofread scans. Collection Assistants can perform these functions, only
    # restricted to the titles that are associated with their site. These
    # functions are available exclusively to these roles, also known as
    # "catalog administrator" roles, through the catalog endpoint.
    #
    def get_catalog(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'catalog', opt)
      ApiTitleMetadataCompleteList.new(response, error: exception)
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

  end unless defined?(Title)

end

__loading_end(__FILE__)
