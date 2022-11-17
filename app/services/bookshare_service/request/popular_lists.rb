# app/services/bookshare_service/request/popular_lists.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::Periodicals
#
# == Usage Notes
#
# === From API section 2.10 (Popular Lists):
# Popular Lists represents several collections of titles that are most popular
# on Bookshare. These include the most popular titles over the last year, over
# the last month, and by category.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::PopularLists

  include BookshareService::Common
  include BookshareService::Testing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/popularLists
  #
  # == 2.10.1 Get the popular lists
  # Get the list of all available popular lists.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]  :start
  # @option opt [Integer] :limit      Default: 10
  #
  # @return [Bs::Message::PopularListList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-popular-lists
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_popular_lists(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'popularLists', **opt)
    api_return(Bs::Message::PopularListList)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
        },
        role:         :anonymous, # Should succeed for any user.
        reference_id: '_get-popular-lists'
      }
    end

  # == GET /v2/popularLists/(popularListId)
  #
  # == 2.10.2. Get a list of popular titles
  # Get metadata for the specified Bookshare periodical.
  #
  # @param [String] popularListId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::PopularList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-popular-list
  #
  # == Usage Notes
  # This request can be made without an Authorization header.
  #
  def get_popular_list(popularListId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'popularLists', popularListId, **opt)
    api_return(Bs::Message::PopularList)
  end
    .tap do |method|
      add_api method => {
        required: {
          popularListId: String,
        },
        role:            :anonymous, # Should succeed for any user.
        reference_id:    '_get-popular-list'
      }
    end

end

__loading_end(__FILE__)
