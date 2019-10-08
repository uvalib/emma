# app/services/api_service/titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Titles
#
# == Usage Notes
#
# === From API section 2.1 (Titles):
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
module ApiService::Titles

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  TITLES_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  TITLES_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/titles/count
  #
  # == 2.1.6. Live title count
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
    .tap do |method|
      add_api method => {
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_title-count'
      }
    end

  # == GET /v2/titles/{bookshareId}
  #
  # == 2.1.2. Get title metadata
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
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
        },
        role:          :anonymous, # Should succeed for any user.
        reference_id:  '_title-metadata'
      }
    end

  # == GET /v2/titles/{bookshareId}/{format}
  #
  # == 2.1.3. Download a title
  # Request download of Bookshare artifact (a title in a specific format).
  #
  # @param [String]     bookshareId
  # @param [FormatType] format
  # @param [Hash]       opt           Optional API URL parameters.
  #
  # @option opt [String] :forUser
  #
  # @return [ApiStatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-download
  #
  def download_title(bookshareId:, format:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', bookshareId, format, **opt)
    ApiStatusModel.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      FormatType,
        },
        optional: {
          forUser:     String,
        },
        reference_id:  '_title-download'
      }
    end

  # == GET /v2/titles
  #
  # == 2.1.1. Search for titles
  # Search for Bookshare titles.
  #
  # @param [Hash] opt                 Optional API URL parameters.
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
  # @option opt [NarratorType]                 :narratorType
  # @option opt [BrailleType]                  :brailleType
  # @option opt [Integer]                      :readingAge
  # @option opt [ContentWarning,Array<ContentWarning>] :excludedContentWarnings
  # @option opt [ContentWarning,Array<ContentWarning>] :includedContentWarnings
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
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', **opt)
    ApiTitleMetadataSummaryList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          title:                   String,
          author:                  String,
          narrator:                String,
          composer:                String,
          keyword:                 String,
          isbn:                    String,
          categories:              String,
          language:                IsoLanguage,
          country:                 String,
          format:                  FormatType,
          narratorType:            NarratorType,
          brailleType:             BrailleType,
          readingAge:              Integer,
          excludedContentWarnings: ContentWarning,
          includedContentWarnings: ContentWarning,
          externalIdentifierCode:  String,
          maxDuration:             IsoDuration,
          titleContentType:        TitleContentType,
          start:                   String,
          limit:                   Integer,
          sortOrder:               TitleSortOrder,
          direction:               Direction,
        },
        multi: %i[
          author narrator composer categories
          excludedContentWarnings includedContentWarnings
        ],
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_title-search'
      }
    end

  # == GET /v2/titles/{bookshareId}?format={format}
  #
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
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      FormatType,
        },
        reference_id:  nil,
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/titles/{bookshareId}/{format}/resources
  #
  # == 2.1.4. Get a list of title file resources
  #
  # @param [String]     bookshareId
  # @param [FormatType] format
  # @param [Hash]       opt           Optional API URL parameters.
  #
  # @option opt [String] :start
  #
  # @return [ApiTitleFileResourceList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-title-file-resource-list
  #
  def get_title_resource_files(bookshareId:, format:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', bookshareId, format, 'resources', **opt)
    ApiTitleFileResourceList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      FormatType,
        },
        optional: {
          start:       String,
        },
        reference_id:  '_get-title-file-resource-list'
      }
    end

  # == GET /v2/titles/{bookshareId}/{format}/resources/{resourceId}
  #
  # == 2.1.5. Download a title file resource
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
    api(:get, 'titles', bookshareId, format, 'resources', resourceId)
    ApiStatusModel.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      FormatType,
          resourceId:  String,
        },
        reference_id:  '_get-title-file-resource'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/categories
  #
  # == 2.1.7. Category listing
  # Search for Bookshare categories.
  #
  # @param [Hash] opt                 Optional API URL parameters.
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
    opt = get_parameters(__method__, **opt)
    api(:get, 'categories', **opt)
    ApiCategoriesList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
        },
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_categories'
      }
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
    response_table = TITLES_SEND_RESPONSE
    message_table  = TITLES_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::TitleError, message
  end

end

__loading_end(__FILE__)
