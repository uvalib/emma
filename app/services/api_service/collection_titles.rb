# app/services/api_service/collection_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::CollectionTitles
#
# == Usage Notes
#
# === From API section 2.8 (Collection Assistant - Titles):
# Administrative users have resources available that will let them manage the
# collection, either by adding or removing titles, or by manipulating their
# metadata.  This could include withdrawing live titles, publishing pending
# titles, or reviewing proofread scans.  Collection Assistants can perform
# these functions, only restricted to the titles that are associated with their
# site.
#
# noinspection RubyParameterNamingConvention
module ApiService::CollectionTitles

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  COLLECTION_TITLES_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  COLLECTION_TITLES_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/catalog
  #
  # == 2.8.1. Search for titles across the catalog
  # For allowed roles, you can ask for titles that might not be visible to
  # regular users, such as those that were once in the collection, but have
  # since been removed. This allows administrators to manage the wider
  # collection of titles.
  #
  # @param [Hash] opt                 Optional API URL parameters.
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
  def get_catalog(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'catalog', **opt)
    ApiTitleMetadataCompleteList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          country:    String,
          isbn:       String,
          start:      String,
          limit:      Integer,
          sortOrder:  CatalogSortOrder,
          direction:  Direction,
        },
        reference_id: '_catalog-search'
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
    response_table = COLLECTION_TITLES_SEND_RESPONSE
    message_table  = COLLECTION_TITLES_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::TitleError, message
  end

end

__loading_end(__FILE__)
