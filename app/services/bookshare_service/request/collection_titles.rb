# app/services/bookshare_service/request/collection_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::CollectionTitles
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
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::CollectionTitles

  include BookshareService::Common

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
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]           :country
  # @option opt [String]           :isbn
  # @option opt [String]           :start
  # @option opt [Integer]          :limit        Default: 10
  # @option opt [CatalogSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]        :direction    Default: 'asc'
  #
  # @return [Bs::Message::TitleMetadataCompleteList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_catalog-search
  #
  def get_catalog(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'catalog', **opt)
    Bs::Message::TitleMetadataCompleteList.new(response, error: exception)
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

end

__loading_end(__FILE__)
