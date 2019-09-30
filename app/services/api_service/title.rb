# app/services/api_service/title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Title
#
# == Usage Notes
#
# === According to API section 2.1 (Titles):
# A title represents a unique entry in the Bookshare collection. They are
# available to users based on a combination of the characteristics of the user
# (their subscription, their address, their age, etc) and the characteristics
# of the title (its distribution area, whether it is copyrighted, etc).
# Users can request a metadata representation of almost any title, but they can
# only request a file download if the user and title characteristics allow, and
# if the requested format is available for the particular title. The title
# metadata resource is where you will find links to the specific file format
# resources that are available for each specific title.
#
# noinspection RubyParameterNamingConvention
module ApiService::Title

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

  # URL parameter fields which, if passed in as an array, are transformed into
  # a list of space-separated values.
  #
  # @type [Array<Symbol>]
  #
  MULTIVALUED_FIELDS = %i[author narrator composer].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/titles/count
  # Get the current count of Bookshare titles.
  #
  # @return [Integer]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-count
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_title_count(*)
    api(:get, 'titles', 'count')
    data = response&.body&.presence
    data.to_i
  end

  # == GET /v2/titles/{bookshareId}
  # Get metadata for the specified Bookshare title.
  #
  # NOTE: The API currently returns :artifacts as *nil*.
  #
  # @param [String] bookshareId
  #
  # @return [ApiTitleMetadataDetail]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-metadata
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_title(bookshareId:)
    api(:get, 'titles', bookshareId)
    ApiTitleMetadataDetail.new(response, error: exception)
  end

  # == GET /v2/titles/{bookshareId}/{format}
  # Download a Bookshare title artifact.
  #
  # @param [String]     bookshareId
  # @param [FormatType] format
  # @param [Hash]       opt           API URL parameters
  #
  # @option opt [String] :forUser
  #
  # @return [ApiStatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-download
  #
  def download_title(bookshareId:, format:, **opt)
    validate_parameters(__method__, opt)
    api(:get, 'titles', bookshareId, format, **opt)
    ApiStatusModel.new(response, error: exception)
  end

  # == GET /v2/titles
  # Search for Bookshare titles.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String]                       :title
  # @option opt [String, Array<String>]        :author
  # @option opt [String, Array<String>]        :narrator
  # @option opt [String, Array<String>]        :composer
  # @option opt [String]                       :keyword
  # @option opt [String]                       :isbn
  # @option opt [String, Array<String>]        :categories
  # @option opt [IsoLanguage]                  :language
  # @option opt [String]                       :country
  # @option opt [FormatType]                   :format
  # @option opt [FormatType]                   :fmt       Alias for :format
  # @option opt [NarratorType]                 :narratorType
  # @option opt [BrailleType]                  :brailleType
  # @option opt [Integer]                      :readingAge
  # @option opt [ContentWarning, Array<String] :excludedContentWarnings
  # @option opt [ContentWarning, Array<String] :includedContentWarnings
  # @option opt [String]                       :externalIdentifierCode
  # @option opt [IsoDuration]                  :maxDuration
  # @option opt [TitleContentType]             :titleContentType
  # @option opt [String]                       :start
  # @option opt [Integer]                      :limit
  # @option opt [TitleSortOrder]               :sortOrder
  # @option opt [Direction]                    :direction
  #
  # @return [ApiTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-search
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_titles(**opt)
    validate_parameters(__method__, opt)
    transformed_opt =
      MULTIVALUED_FIELDS.map { |field|
        next unless opt[field].is_a?(Array)
        terms = opt[field].map { |v| %Q("#{v}") }.join(' ')
        [field, terms]
      }.compact.to_h
    opt = opt.merge(transformed_opt) if transformed_opt.present?
    api(:get, 'titles', **opt)
    ApiTitleMetadataSummaryList.new(response, error: exception)
  end

  # == GET /v2/titles/{bookshareId}?format={format}
  # Get the metadata of an existing artifact.
  #
  # @param [String]     bookshareId
  # @param [FormatType] format
  #
  # @return [Api::ArtifactMetadata]
  # @return [nil]                     If the requested format was not present.
  #
  # NOTE: This is not a real Bookshare API call.
  #
  def get_artifact_metadata(bookshareId:, format:)
    title = get_title(bookshareId: bookshareId)
    title.artifact_list.find { |a| format == a.format }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/titles/{bookshareId}/{format}/resources
  # Get a list of title file resources.
  #
  # @param [String]     bookshareId
  # @param [FormatType] format
  # @param [Hash]       opt           API URL parameters
  #
  # @option opt [String] :start
  #
  # @return [ApiTitleFileResourceList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-title-file-resource-list
  #
  def get_title_resource_files(bookshareId:, format:, **opt)
    validate_parameters(__method__, opt)
    api(:get, 'titles', bookshareId, format, 'resources', **opt)
    ApiTitleFileResourceList.new(response, error: exception)
  end

  # == GET /v2/titles/{bookshareId}/{format}/resources/{resourceId}
  # Get a title file resource.
  #
  # @param [String]     bookshareId
  # @param [FormatType] format
  # @param [String]     resourceId
  #
  # @return [ApiStatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-title-file-resource
  #
  def get_title_resource_file(bookshareId:, format:, resourceId:)
    validate_parameters(__method__, opt)
    api(:get, 'titles', bookshareId, format, 'resources', resourceId)
    ApiStatusModel.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/categories
  # Search for Bookshare categories.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String]  :start
  # @option opt [Integer] :limit      Default: 100
  #
  # @return [ApiCategoriesList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_categories
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_categories(**opt)
    validate_parameters(__method__, opt)
    api(:get, 'categories', **opt)
    ApiCategoriesList.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/catalog
  # For allowed roles, you can ask for titles that might not be visible to
  # regular users, such as those that were once in the collection, but have
  # since been removed. This allows administrators to manage the wider
  # collection of titles.
  #
  # @param [Hash] opt                 API URL parameters
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
  # @see https://apidocs.bookshare.org/reference/index.html#_catalog-search
  #
  # == Usage Notes
  #
  # === According to API section 2.8 (Collection Assistant - Titles):
  # Administrative users can search and update the entire collection of titles,
  # not just those that are live for the public to see. This could include
  # withdrawing live titles, publishing pending titles, or reviewing proofread
  # scans. Collection Assistants can perform these functions, only restricted
  # to the titles that are associated with their site. These functions are
  # available exclusively to these roles, also known as "catalog administrator"
  # roles, through the catalog endpoint.
  #
  def get_catalog(**opt)
    validate_parameters(__method__, opt)
    api(:get, 'catalog', **opt)
    ApiTitleMetadataCompleteList.new(response, error: exception)
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
    response_table = TITLE_SEND_RESPONSE
    message_table  = TITLE_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::TitleError, message
  end

end

__loading_end(__FILE__)
