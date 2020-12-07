# app/services/bookshare_service/request/reading_lists.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::ReadingLists
#
# == Usage Notes
#
# === From API section 2.3 (Reading Lists):
# Reading lists can be created and deleted by individual members and sponsors,
# and titles can be added and removed from them. For sponsors, these lists can
# also be shared with student members to serve as a type of class syllabus.
# To do so, a sponsor can add a member from their organization to the reading
# list, and that member will be able to use that list but will not be able to
# modify it.
#
#--
# noinspection RubyParameterNamingConvention
#++
module BookshareService::Request::ReadingLists

  include BookshareService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/mylists
  #
  # == 2.3.1. Get my reading lists
  # Get the reading lists visible to the current user (private lists, shared
  # lists, or organization lists that the user is subscribed to).
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                 :start
  # @option opt [Integer]                :limit       Default: 10
  # @option opt [MyReadingListSortOrder] :sortOrder   Default: 'name'
  # @option opt [Direction]              :direction   Default: 'asc'
  #
  # @return [Bs::Message::ReadingListList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-my-readinglists-list
  #
  def get_my_reading_lists(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'mylists', **opt)
    Bs::Message::ReadingListList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
          sortOrder:  MyReadingListSortOrder,
          direction:  Direction,
        },
        reference_id: '_get-my-readinglists-list'
      }
    end

  # == POST /v2/mylists
  #
  # == 2.3.2. Create a reading list
  # Create an empty reading list owned by the current user.
  #
  # @param [String] name
  # @param [Access] access
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String] :description
  #
  # @return [Bs::Message::ReadingList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_post-readinglist-create
  #
  def create_my_reading_list(name:, access:, **opt)
    opt.merge!(name: name, access: access)
    opt = get_parameters(__method__, **opt)
    api(:post, 'mylists', **opt)
    Bs::Message::ReadingList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          name:        String,
          access:      Access,
        },
        optional: {
          description: String,
        },
        reference_id:  '_post-readinglist-create'
      }
    end

  # == PUT /v2/mylists/{readingListId}/subscription
  #
  # == 2.3.7. Subscribe to or unsubscribe from a reading list
  # Subscribe to a reading list (that the user does not own).
  #
  # @param [String] readingListId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [Boolean] :enabled    Default: *true*.
  #
  # @return [Bs::Message::ReadingListUserView]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-readinglist-subscription
  #
  def subscribe_my_reading_list(readingListId:, **opt)
    opt.reverse_merge!(enabled: true)
    opt = get_parameters(__method__, **opt)
    api(:put, 'mylists', readingListId, 'subscription', **opt)
    Bs::Message::ReadingListUserView.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          readingListId: String,
          enabled:       Boolean,
        },
        reference_id:    '_put-readinglist-subscription'
      }
    end

  # == PUT /v2/mylists/{readingListId}/subscription
  #
  # == 2.3.7. Subscribe to or unsubscribe from a reading list
  # Unsubscribe from a reading list (that the user does not own).
  #
  # @param [String] readingListId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [Boolean] :enabled    Default: *false*.
  #
  # @return [Bs::Message::ReadingListUserView]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-readinglist-subscription
  #
  def unsubscribe_my_reading_list(readingListId:, **opt)
    opt.reverse_merge!(enabled: false)
    opt = get_parameters(__method__, **opt)
    api(:put, 'mylists', readingListId, 'subscription', **opt)
    Bs::Message::ReadingListUserView.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          readingListId: String,
          enabled:       Boolean,
        },
        reference_id:    nil,
      }
    end

  # == GET /v2/lists
  # Get all reading lists.
  #
  # Whereas "/v2/mylists" only works for "emmadso@bookshare.org", this call
  # works for "emmacollection@bookshare.org" (and for "emmadso" it yields the
  # same result as "/v2/mylists").
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]                 :start
  # @option opt [Integer]                :limit       Default: 10
  # @option opt [MyReadingListSortOrder] :sortOrder   Default: 'name'
  # @option opt [Direction]              :direction   Default: 'asc'
  #
  # @return [Bs::Message::ReadingListList]
  #
  # NOTE: This is an undocumented Bookshare API call.
  #
  def get_all_reading_lists(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'lists', **opt)
    Bs::Message::ReadingListList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
          sortOrder:  MyReadingListSortOrder,
          direction:  Direction,
        },
        reference_id: '_get-all-reading-lists', # TODO: ???
      }
    end

  # == GET /v2/lists/{readingListId}
  # Get metadata for an existing reading list.
  #
  # @param [String] readingListId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::ReadingListUserView]
  #
  # NOTE: This is not a real Bookshare API call.
  #
  def get_reading_list(readingListId:, **opt)
    all = get_all_reading_lists(limit: :max, **opt)
    rl  = all.lists.find { |list| list.identifier == readingListId }
    # noinspection RubyYardParamTypeMatch
    Bs::Message::ReadingListUserView.new(rl)
  end
    .tap do |method|
      add_api method => {
        required: {
          readingListId: String,
        },
        reference_id:    nil,
      }
    end

  # == PUT /v2/lists/{readingListId}
  #
  # == 2.3.3. Edit reading list metadata
  # Edit the metadata of an existing reading list.
  #
  # @param [String] readingListId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String] :name
  # @option opt [String] :description
  # @option opt [Access] :access
  #
  # @return [Bs::Message::ReadingList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-readinglist-edit-metadata
  #
  def update_reading_list(readingListId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'lists', readingListId, **opt)
    Bs::Message::ReadingList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          readingListId: String,
        },
        optional: {
          name:          String,
          description:   String,
          access:        Access,
        },
        reference_id:    '_put-readinglist-edit-metadata'
      }
    end

  # == GET /v2/lists/{readingListId}/titles
  #
  # == 2.3.4. Get reading list titles
  # Get a listing of the Bookshare titles in the specified reading list.
  #
  # @param [String] readingListId
  # @param [Hash]   opt               Passed to #api.
  #
  # @option opt [String]               :start
  # @option opt [Integer]              :limit       Default: 10
  # @option opt [ReadingListSortOrder] :sortOrder   Default: 'title'
  # @option opt [Direction]            :direction   Default: 'asc'
  #
  # @return [Bs::Message::ReadingListTitlesList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-readinglist-titles
  #
  def get_reading_list_titles(readingListId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'lists', readingListId, 'titles', **opt)
    Bs::Message::ReadingListTitlesList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          readingListId: String,
        },
        optional: {
          start:         String,
          limit:         Integer,
          sortOrder:     ReadingListSortOrder,
          direction:     Direction,
        },
        reference_id:    '_get-readinglist-titles'
      }
    end

  # == POST /v2/lists/{readingListId}/titles
  #
  # == 2.3.5. Add a title to a reading list
  # Add a Bookshare title to the specified reading list.
  #
  # @param [String] readingListId
  # @param [String] bookshareId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::ReadingListTitlesList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_post-readinglist-title
  #
  def create_reading_list_title(readingListId:, bookshareId:, **opt)
    opt.merge!(bookshareId: bookshareId)
    opt = get_parameters(__method__, **opt)
    api(:post, 'lists', readingListId, 'titles', **opt)
    Bs::Message::ReadingListTitlesList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          readingListId: String,
          bookshareId:   String,
        },
        reference_id:    '_post-readinglist-title'
      }
    end

  # == DELETE /v2/lists/{readingListId}/titles/{bookshareId}
  #
  # == 2.3.6. Remove a title from a reading list
  # Remove a title from the specified reading list.
  #
  # @param [String] readingListId
  # @param [String] bookshareId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [Bs::Message::ReadingListTitlesList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_delete-readinglist-title
  #
  def remove_reading_list_title(readingListId:, bookshareId:, **opt)
    opt = get_parameters(__method__, **opt)
    api(:delete, 'lists', readingListId, 'titles', bookshareId, **opt)
    Bs::Message::ReadingListTitlesList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          readingListId: String,
          bookshareId:   String,
        },
        reference_id:    '_delete-readinglist-title'
      }
    end

end

__loading_end(__FILE__)
