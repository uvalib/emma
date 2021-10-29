# app/services/bookshare_service/request/titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::Titles
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
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/titles/count
  #
  # == 2.1.6. Live title count
  # Get a count of the live titles available in the collection which the user
  # has access to. The boundaries of that can be adjusted to include titles
  # shared from other partners or not, or to view the collection from a country
  # other than that of the current user.
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
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', 'count', **opt)
    response&.body&.presence&.to_i || exception
  end
    .tap do |method|
      add_api method => {
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_title-count'
      }
    end

  # == GET /v2/titles/(bookshareId)
  #
  # == 2.1.2. Get title metadata
  # Get metadata for the specified Bookshare title.
  #
  # NOTE: The Bookshare API currently returns :artifacts as *nil*.
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
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', bookshareId, **opt)
    api_return(Bs::Message::TitleMetadataDetail)
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

  # == GET /v2/titles/(bookshareId)/(format)
  #
  # == 2.1.3. Download a title
  # Ask to download a title in a specific format. This will request a package
  # of a title artifact, which will be fingerprinted and watermarked to
  # indicate it’s delivery to either the current user, or the 'forUser' if that
  # is specified. If the package is not available immediately, requests to this
  # endpoint will simply return a status to acknowledge receipt. Subsequent
  # requests will eventually return a reference to the delivery file for the
  # given format (ZIP, EPUB, PDF, etc).
  #
  # @param [String]       bookshareId
  # @param [BsFormatType] format
  # @param [Hash]         opt         Passed to #api.
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
    api(:get, 'titles', bookshareId, format, **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      BsFormatType,
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
  # To discover titles in the collection, you can ask for the collection of
  # title resources, filtered by a number of criteria such as title, author,
  # ISBN, keyword or country availability. A search on keyword will search the
  # title, author, and ISBN fields for that keyword. Keyword searches may be
  # further filtered by an author filter parameter, but any other parameters
  # will be ignored. The result will be a collection of title metadata
  # resources, with a paging token if the results are more than the paging
  # limit.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                  :title
  # @option opt [String, Array<String>]   :author
  # @option opt [String, Array<String>]   :narrator
  # @option opt [String, Array<String>]   :composer
  # @option opt [String]                  :keyword
  # @option opt [String]                  :isbn
  # @option opt [String, Array<String>]   :categories
  # @option opt [IsoLanguage]             :language
  # @option opt [String]                  :country
  # @option opt [BsFormatType]            :format
  # @option opt [BsNarratorType]          :narratorType
  # @option opt [BsBrailleType]           :brailleType
  # @option opt [Integer]                 :readingAge
  # @option opt [Array<BsContentWarning>] :excludedContentWarnings
  # @option opt [Array<BsContentWarning>] :includedContentWarnings
  # @option opt [String]                  :externalIdentifierCode
  # @option opt [IsoDuration]             :maxDuration
  # @option opt [BsTitleContentType]      :titleContentType
  # @option opt [String]                  :start
  # @option opt [Integer]                 :limit
  # @option opt [BsTitleSortOrder]        :sortOrder
  # @option opt [BsSortDirection]         :direction
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
    api_return(Bs::Message::TitleMetadataSummaryList)
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
          format:                  BsFormatType,
          narratorType:            BsNarratorType,
          brailleType:             BsBrailleType,
          readingAge:              Integer,
          excludedContentWarnings: BsContentWarning,
          includedContentWarnings: BsContentWarning,
          externalIdentifierCode:  String,
          maxDuration:             IsoDuration,
          titleContentType:        BsTitleContentType,
          start:                   String,
          limit:                   Integer,
          sortOrder:               BsTitleSortOrder,
          direction:               BsSortDirection,
        },
        multi: %i[
          author narrator composer categories
          excludedContentWarnings includedContentWarnings
        ],
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_title-search'
      }
    end

  # == GET /v2/titles/(bookshareId)?format=(format)
  #
  # Get the metadata of an existing artifact.
  #
  # @param [String]       bookshareId
  # @param [BsFormatType] format
  # @param [Hash]         opt         Passed to #api.
  #
  # @return [Bs::Message::ArtifactMetadata]
  # @return [nil]                     If the requested format was not present.
  #
  # @note This is not a real Bookshare API call.
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
          format:      BsFormatType,
        },
        reference_id:  nil,
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/titles/(bookshareId)/(format)/resources
  #
  # == 2.1.4. Get a list of title file resources
  #
  # @param [String]       bookshareId
  # @param [BsFormatType] format
  # @param [Hash]         opt         Passed to #api.
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
    api_return(Bs::Message::TitleFileResourceList)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      BsFormatType,
        },
        optional: {
          start:       String,
        },
        reference_id:  '_get-title-file-resource-list'
      }
    end

  # == GET /v2/titles/(bookshareId)/(format)/resources/(resourceId)
  #
  # == 2.1.5. Download a title file resource
  # Download a single title file resource that is part of a title artifact.
  # Note: this URL will be constructed by the system, and appear in the title
  # file resources response.
  #
  # @param [String]       bookshareId
  # @param [BsFormatType] format
  # @param [String]       resourceId
  # @param [Hash]         opt         Passed to #api.
  #
  # @option opt [String] :size        *REQUIRED*
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-title-file-resource
  #
  def get_title_resource_file(bookshareId:, format:, resourceId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'titles', bookshareId, format, 'resources', resourceId, **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      BsFormatType,
          resourceId:  String,
          size:        String,
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
  # Get a list of categories defined on the collection, with a count of titles
  # associated with each category. The count reflects the number of titles that
  # the current user would have access to. The categories include only those
  # with at least one title association.
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
    api_return(Bs::Message::CategoriesList)
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
    api(:get, url, **opt)
    api_return(Search::Message::RetrievalResult)
  end

end

__loading_end(__FILE__)
