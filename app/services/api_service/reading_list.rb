# app/services/api_service/reading_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::ReadingList
#
# == Usage Notes
#
# === According to API section 2.3 (Reading Lists):
# Reading lists can be created and deleted by individual members and sponsors,
# and titles can be added and removed from them. For sponsors, these lists can
# also be shared with student members to serve as a type of class syllabus.
# To do so, a sponsor can add a member from their organization to the reading
# list, and that member will be able to use that list but will not be able to
# modify it.
#
# noinspection RubyParameterNamingConvention
module ApiService::ReadingList

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  READING_LIST_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  READING_LIST_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/mylists
  # Get the reading lists visible to the current user.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String]                 :start
  # @option opt [Integer]                :limit       Default: 10
  # @option opt [MyReadingListSortOrder] :sortOrder   Default: 'name'
  # @option opt [Direction]              :direction   Default: 'asc'
  #
  # @return [ApiReadingListList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-my-readinglists-list
  #
  def get_my_reading_lists(**opt)
    validate_parameters(__method__, opt)
    api(:get, 'mylists', **opt)
    ApiReadingListList.new(response, error: exception)
  end

  # == POST /v2/mylists
  # Create an empty reading list owned by the current user.
  #
  # @param [String] name
  # @param [Hash]   opt               API URL parameters
  #
  # @option opt [String] :description
  # @option opt [Access] :access
  #
  # @return [ApiReadingList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_post-readinglist-create
  #
  def create_reading_list(name:, **opt)
    validate_parameters(__method__, opt)
    opt = opt.reverse_merge(name: name)
    api(:post, 'mylists', **opt)
    ApiReadingList.new(response, error: exception)
  end

  # == PUT /v2/mylists/{readingListId}/subscription
  # Subscribe to a reading list (that the user does not own).
  #
  # @param [String] readingListId
  # @param [Hash]   opt               API URL parameters
  #
  # @options opt [Boolean] :enabled   Default: true
  #
  # @return [ApiReadingListUserView]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-readinglist-subscription
  #
  def subscribe_reading_list(readingListId:, **opt)
    validate_parameters(__method__, opt)
    opt = opt.reverse_merge(enabled: true)
    api(:put, 'mylists', readingListId, 'subscription', **opt)
    ApiReadingListUserView.new(response, error: exception)
  end

  # == PUT /v2/mylists/{readingListId}/subscription
  # Unsubscribe from a reading list (that the user does not own).
  #
  # @param [String] readingListId
  # @param [Hash]   opt               API URL parameters
  #
  # @options opt [Boolean] :enabled   Default: false
  #
  # @return [ApiReadingListUserView]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-readinglist-subscription
  #
  def unsubscribe_reading_list(readingListId:, **opt)
    validate_parameters(__method__, opt)
    opt = opt.reverse_merge(enabled: false)
    api(:put, 'mylists', readingListId, 'subscription', **opt)
    ApiReadingListUserView.new(response, error: exception)
  end

  # == GET /v2/lists
  # Get all reading lists.
  #
  # Whereas "/v2/mylists" only works for "emmadso@bookshare.org", this call
  # works for "emmacollection@bookshare.org" (and for "emmadso" it yields the
  # same result as "/v2/mylists").
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String]                 :start
  # @option opt [Integer]                :limit       Default: 10
  # @option opt [MyReadingListSortOrder] :sortOrder   Default: 'name'
  # @option opt [Direction]              :direction   Default: 'asc'
  #
  # @return [ApiReadingListList]
  #
  # NOTE: This is an undocumented Bookshare API call.
  #
  def get_reading_lists(**opt)
    validate_parameters(__method__, opt)
    api(:get, 'lists', **opt)
    ApiReadingListList.new(response, error: exception)
  end

  # == GET /v2/lists/{readingListId}
  # Get metadata for an existing reading list.
  #
  # @param [String] readingListId
  #
  # @return [ApiReadingListUserView]
  #
  # NOTE: This is not a real Bookshare API call.
  #
  def get_reading_list(readingListId:)
    all = get_reading_lists(limit: :max)
    rl  = all.lists.find { |list| list.identifier == readingListId }
    ApiReadingListUserView.new(rl)
  end

  # == PUT /v2/lists/{readingListId}
  # Edit the metadata of an existing reading list.
  #
  # @param [String] readingListId
  # @param [Hash]   opt               API URL parameters
  #
  # @option opt [String] :name
  # @option opt [String] :description
  # @option opt [Access] :access
  #
  # @return [ApiReadingList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-readinglist-edit-metadata
  #
  def update_reading_list(readingListId:, **opt)
    validate_parameters(__method__, opt)
    api(:put, 'lists', readingListId, **opt)
    ApiReadingList.new(response, error: exception)
  end

  # == GET /v2/lists/{readingListId}/titles
  # Get a listing of the Bookshare titles in the specified reading list.
  #
  # @param [String] readingListId
  # @param [Hash]   opt               API URL parameters
  #
  # @option opt [String]               :start
  # @option opt [Integer]              :limit       Default: 10
  # @option opt [ReadingListSortOrder] :sortOrder   Default: 'title'
  # @option opt [Direction]            :direction   Default: 'asc'
  #
  # @return [ApiReadingListTitlesList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-readinglist-titles
  #
  def get_reading_list_titles(readingListId:, **opt)
    validate_parameters(__method__, opt)
    api(:get, 'lists', readingListId, 'titles', **opt)
    ApiReadingListTitlesList.new(response, error: exception)
  end

  # == POST /v2/lists/{readingListId}/titles
  # Add a Bookshare title to the specified reading list.
  #
  # @param [String] readingListId
  # @param [String] bookshareId
  # @param [Hash]   opt               API URL parameters
  #
  # @return [ApiReadingListTitlesList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_post-readinglist-title
  #
  def create_reading_list_title(readingListId:, bookshareId:, **opt)
    validate_parameters(__method__, opt)
    opt = opt.reverse_merge(bookshareId: bookshareId)
    api(:post, 'lists', readingListId, 'titles', **opt)
    ApiReadingListTitlesList.new(response, error: exception)
  end

  # == DELETE /v2/lists/{readingListId}/titles/{bookshareId}
  # Remove a title from the specified reading list.
  #
  # @param [String] readingListId
  # @param [String] bookshareId
  # @param [Hash]   opt               API URL parameters
  #
  # @return [ApiReadingListTitlesList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_delete-readinglist-title
  #
  def remove_reading_list_title(readingListId:, bookshareId:, **opt)
    validate_parameters(__method__, opt)
    api(:delete, 'lists', readingListId, 'titles', bookshareId, **opt)
    ApiReadingListTitlesList.new(response, error: exception)
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
    response_table = READING_LIST_SEND_RESPONSE
    message_table  = READING_LIST_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::ReadingListError, message
  end

end

__loading_end(__FILE__)
