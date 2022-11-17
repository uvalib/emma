# app/services/bookshare_service/request/periodicals.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::Periodicals
#
# == Usage Notes
#
# === From API section 2.2 (Periodicals):
# A periodical represents a magazine or newspaper, each of which can have
# multiple editions/issues. The editions/issues are available to users in the
# same way as titles, based on characteristics of the user and the
# periodical, and in formats that will be specified in the response.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::Periodicals

  include BookshareService::Common
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/periodicals
  #
  # == 2.2.1. Search for periodicals
  # To discover periodicals in the collection, you can ask for the collection
  # of periodical series resources, filtered by a title string or ISSN. The
  # result will be a collection of periodical series metadata resources, with a
  # paging token if the results are more than the paging limit.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                :title
  # @option opt [String]                :issn
  # @option opt [IsoLanguage]           :language
  # @option opt [String]                :start
  # @option opt [Integer]               :limit        Default: 10
  # @option opt [BsPeriodicalSortOrder] :sortOrder    Default: 'title'
  # @option opt [BsSortDirection]       :direction    Default: 'asc'
  #
  # @return [Bs::Message::PeriodicalSeriesMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-search
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_periodicals(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'periodicals', **opt)
    api_return(Bs::Message::PeriodicalSeriesMetadataSummaryList)
  end
    .tap do |method|
      add_api method => {
        optional: {
          title:      String,
          issn:       String,
          language:   IsoLanguage,
          start:      String,
          limit:      Integer,
          sortOrder:  BsPeriodicalSortOrder,
          direction:  BsSortDirection,
        },
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_periodical-search'
      }
    end

  # == GET /v2/periodicals/(seriesId)
  #
  # == 2.2.3. Get periodical series metadata
  # Get metadata for the specified Bookshare periodical.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSeriesMetadataSummary]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-series-metadata
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_periodical(seriesId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'periodicals', seriesId, **opt)
    api_return(Bs::Message::PeriodicalSeriesMetadataSummary)
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

  # == GET /v2/periodicals/(seriesId)/editions
  #
  # == 2.2.2. Get periodical editions
  # Get a list editions for a periodical. The result will be a collection of
  # periodical edition resources, with a paging token if the results are more
  # than the paging limit.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [Integer]            :limit       Default: 10
  # @option opt [BsEditionSortOrder] :sortOrder   Default: 'editionName'
  # @option opt [BsSortDirection]    :direction   Default: 'asc'
  #
  # @return [Bs::Message::PeriodicalEditionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-editions
  #
  def get_periodical_editions(seriesId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'periodicals', seriesId, 'editions', **opt)
    api_return(Bs::Message::PeriodicalEditionList)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
        },
        optional: {
          limit:      Integer,
          sortOrder:  BsEditionSortOrder,
          direction:  BsSortDirection,
        },
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_periodical-editions'
      }
    end

  # == GET /v2/periodicals/(seriesId)/editions/(editionId)
  #
  # Get the metadata of an existing periodical edition.
  #
  # @param [String] seriesId
  # @param [String] editionId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Record::PeriodicalEdition]
  # @return [nil]
  #
  # @note This is not a real Bookshare API call.
  #
  def get_periodical_edition(seriesId:, editionId:, **opt)
    opt[:seriesId] = seriesId
    opt[:limit]    = :max
    periodical = get_periodical_editions(**opt)
    # noinspection RubyMismatchedReturnType
    periodical.periodicalEditions&.find { |pe| editionId == pe.editionId }
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

  # == GET /v2/periodicals/(seriesId)/editions/(editionId)/(format)
  #
  # == 2.2.4. Download a periodical edition
  # Ask for a periodical edition file of a given format. This will request a
  # package of a periodical edition artifact, which will be fingerprinted and
  # watermarked to indicate it’s delivery to either the current user, or the
  # 'forUser' if that is specified. If the package is not available
  # immediately, requests to this endpoint will simply return a status to
  # acknowledge receipt. Subsequent requests will eventually return a reference
  # to the delivery file for the given format (ZIP, EPUB, PDF, etc).
  #
  # @param [String]       seriesId
  # @param [String]       editionId
  # @param [BsFormatType] format
  # @param [Hash]         opt         Passed to #api.
  #
  # @option opt [String] :forUser     For restricted items, this is *not*
  #                                     optional -- it must be the
  #                                     :userAccountId of a qualified user.
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_periodical-download
  #
  def download_periodical_edition(seriesId:, editionId:, format:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'periodicals', seriesId, 'editions', editionId, format, **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
          editionId:  String,
          format:     BsFormatType,
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

  # == GET /v2/periodicals/(seriesId)/editions/(editionId)/(format)/resources
  #
  # == 2.2.5. Get a list of title file resources for a periodical
  #
  # @param [String]       seriesId
  # @param [String]       editionId
  # @param [BsFormatType] format
  # @param [Hash]         opt         Passed to #api.
  #
  # @return [Bs::Message::TitleFileResourceList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-periodical-title-file-resource-list
  #
  def get_periodical_resource_files(seriesId:, editionId:, format:, **opt)
    opt  = get_parameters(__method__, **opt)
    path = [seriesId, 'editions', editionId, format, 'resources']
    api(:get, 'periodicals', *path, **opt)
    api_return(Bs::Message::TitleFileResourceList)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
          editionId:  String,
          format:     BsFormatType,
        },
        optional: {
          start:      String,
        },
        reference_id: '_get-periodical-title-file-resource-list'
      }
    end

  # == GET /v2/periodicals/(seriesId)/editions/(editionId)/(format)/resources/(resourceId)
  #
  # == 2.2.6. Download a title file resource for a periodical
  # Download a single title file resource that is part of a periodical
  # artifact. Note: this URL will be constructed by the system, and appear in
  # the periodical file resources response.
  #
  # @param [String]       seriesId
  # @param [String]       editionId
  # @param [BsFormatType] format
  # @param [String]       resourceId
  # @param [Hash]         opt         Passed to #api.
  #
  # @option opt [String] :size        *REQUIRED*
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-periodical-title-file-resource
  #
  def get_periodical_resource_file(
    seriesId:, editionId:, format:, resourceId:, **opt
  )
    opt  = get_parameters(__method__, **opt)
    path = [seriesId, 'editions', editionId, format, 'resources', resourceId]
    api(:get, 'periodicals', *path, **opt)
    api_return(Bs::Message::StatusModel)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:    String,
          editionId:   String,
          format:      BsFormatType,
          resourceId:  String,
          size:        String,
        },
        reference_id:  '_get-periodical-title-file-resource'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myPeriodicals
  #
  # == 2.2.7. Get my periodical subscriptions
  # Get the list of periodical subscriptions for the authenticated user.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myperiodicals
  #
  def get_my_periodicals(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myPeriodicals', **opt)
    api_return(Bs::Message::PeriodicalSubscriptionList)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_get-myperiodicals'
      }
    end

  # == POST /v2/myPeriodicals
  #
  # == 2.2.8. Subscribe to a periodical series
  # Create a periodical subscription for the authenticated user.
  #
  # @param [String]             seriesId
  # @param [BsPeriodicalFormat] format
  # @param [Hash]               opt       Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_subscribe-myperiodicals
  #
  def subscribe_my_periodical(seriesId:, format:, **opt)
    opt.merge!(seriesId: seriesId, format: format)
    opt = get_parameters(__method__, **opt)
    api(:post, 'myPeriodicals', **opt)
    api_return(Bs::Message::PeriodicalSubscriptionList)
  end
    .tap do |method|
      add_api method => {
        required: {
          seriesId:   String,
          format:     BsPeriodicalFormat,
        },
        reference_id: '_subscribe-myperiodicals'
      }
    end

  # == DELETE /v2/myPeriodicals/(seriesId)
  #
  # == 2.2.9. Unsubscribe from a periodical series
  # Remove a periodical subscription for the authenticated user.
  #
  # @param [String] seriesId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_unsubscribe-myperiodicals
  #
  def unsubscribe_my_periodical(seriesId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:delete, 'myPeriodicals', seriesId, **opt)
    api_return(Bs::Message::PeriodicalSubscriptionList)
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
