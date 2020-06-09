# app/services/bookshare_service/request/titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Titles
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
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::Titles

  include BookshareService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/titles/count
  #
  # == 2.1.6. Live title count
  # Get the current count of Bookshare titles.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [Integer]
  # @return [Exception]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-count
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_title_count(**opt)
    api(:get, 'titles', 'count', **opt)
    response&.body&.presence&.to_i || exception
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
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::TitleMetadataDetail]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-metadata
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_title(bookshareId:, **opt)
    api(:get, 'titles', bookshareId, **opt)
    Bs::Message::TitleMetadataDetail.new(response, error: exception)
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

  # The identifier (:userAccountId) for the test member "Placeholder Member".
  #
  # @type [String, nil]
  #
  BOOKSHARE_TEST_MEMBER = 'AP5xvS_OBOox69jMyt_sdVqCgX-OhnuC8oAFynfN3lJIyM56O86KRMdaYcP5MvZD1DmTtFOSGOj7'
    # Rails.root.join('test/fixtures/members.yml').yield_self { |path|
    #   YAML.load_file(path)&.deep_symbolize_keys! || {}
    # }.dig(:Placeholder_Member, :user_id)

  # == GET /v2/titles/{bookshareId}/{format}
  #
  # == 2.1.3. Download a title
  # Request download of Bookshare artifact (a title in a specific format).
  #
  # @param [String]     bookshareId
  # @param [FormatType] format
  # @param [Hash]       opt           Passed to #api.
  #
  # @option opt [String] :forUser     For restricted items, this is *not*
  #                                     optional -- it must be the
  #                                     :userAccountId of a qualified user.
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-download
  #
  def download_title(bookshareId:, format:, **opt)
    opt = get_parameters(__method__, **opt)
    opt[:forUser] ||= BOOKSHARE_TEST_MEMBER if defined?(BOOKSHARE_TEST_MEMBER) # TODO: testing; remove
    api(:get, 'titles', bookshareId, format, **opt)
    Bs::Message::StatusModel.new(response, error: exception)
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
  # @param [Hash] opt                 Passed to #api.
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
  # @return [Bs::Message::TitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-search
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_titles(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', **opt)
    Bs::Message::TitleMetadataSummaryList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          fmt:                     :format,
        },
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
  # @param [Hash]       opt           Passed to #api.
  #
  # @return [Bs::Message::ArtifactMetadata]
  # @return [nil]                     If the requested format was not present.
  #
  # NOTE: This is not a real Bookshare API call.
  #
  def get_artifact_metadata(bookshareId:, format:, **opt)
    title = get_title(bookshareId: bookshareId, **opt)
    # noinspection RubyArgCount
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
  # @param [Hash]       opt           Passed to #api.
  #
  # @option opt [String] :start
  #
  # @return [Bs::Message::TitleFileResourceList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-title-file-resource-list
  #
  def get_title_resource_files(bookshareId:, format:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', bookshareId, format, 'resources', **opt)
    Bs::Message::TitleFileResourceList.new(response, error: exception)
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
  # @param [Hash]       opt           Passed to #api.
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-title-file-resource
  #
  def get_title_resource_file(bookshareId:, format:, resourceId:, **opt)
    api(:get, 'titles', bookshareId, format, 'resources', resourceId, **opt)
    Bs::Message::StatusModel.new(response, error: exception)
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
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]  :start
  # @option opt [Integer] :limit      Default: 100
  #
  # @return [Bs::Message::CategoriesList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_categories
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_categories(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'categories', **opt)
    Bs::Message::CategoriesList.new(response, error: exception)
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

  public

  # Retrieve an artifact by URL.
  #
  # This supports downloads of Bookshare items from EMMA Unified Search results
  # by accepting a full retrieval URL (which is already a fully-formed
  # Bookshare API links sans API key).
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Search::Message::RetrievalResult]
  #
  def get_retrieval(url:, **opt)
    url = url.sub(%r{//api\.qa\.}, '//api.') # TODO: temporary until Benetech fixes unified search
    opt[:forUser] ||= BOOKSHARE_TEST_MEMBER if defined?(BOOKSHARE_TEST_MEMBER) # TODO: testing; remove
    api(:get, url, **opt)
    Search::Message::RetrievalResult.new(response, error: exception)
  end

end

__loading_end(__FILE__)
