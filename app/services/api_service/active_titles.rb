# app/services/api_service/active_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::ActiveTitles
#
# == Usage Notes
#
# === From API section 2.5 (Active Titles):
# Active titles are books or periodicals that a user has chosen to be packaged
# and ready to read in a specific format.  These titles in these formats will
# also show up in the user’s history list, but the active titles represents a
# list that the user can manage themselves, removing titles when they are no
# longer reading them. There are separate endpoints for managing active books
# and active periodicals, since there are different limitations on each of
# them.
#
# noinspection RubyParameterNamingConvention
module ApiService::ActiveTitles

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myActiveBooks
  #
  # == 2.5.1. Get my active books
  # Get a list of my active books that are ready to read.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]              :start
  # @option opt [Integer]             :limit      Default: 10
  # @option opt [ActiveBookSortOrder] :sortOrder  Default: 'dateAdded'
  # @option opt [Direction]           :direction  Default: 'asc'
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-books
  #
  def get_my_active_books(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myActiveBooks', **opt)
    ApiActiveBookList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
          sortOrder:  ActiveBookSortOrder,
          direction:  Direction,
        },
        reference_id: '_my-active-books'
      }
    end

  # == POST /v2/myActiveBooks
  #
  # == 2.5.2. Add active book
  # Add a book to my active books list.
  #
  # @param [String] bookshareId
  # @param [String] format
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-books-add
  #
  def add_my_active_book(bookshareId:, format:, **opt)
    prm = encode_parameters(bookshareId: bookshareId, format: format)
    api(:post, 'myActiveBooks', **prm, **opt)
    ApiActiveBookList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      String,
        },
        reference_id:  '_my-active-books-add'
      }
    end

  # == DELETE /v2/myActiveBooks/{activeTitleId}
  #
  # == 2.5.3. Remove an active book
  # Remove one of the entries from my list of active books.
  #
  # @param [String] activeTitleId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-books-remove
  #
  def remove_my_active_book(activeTitleId:, **opt)
    api(:delete, 'myActiveBooks', activeTitleId, **opt)
    ApiActiveBookList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          activeTitleId: String,
        },
        reference_id:    '_my-active-books-remove'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myActivePeriodicals
  #
  # == 2.5.4. Get my active periodicals
  # Get a list of my active periodicals that are ready to read.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]              :start
  # @option opt [Integer]             :limit      Default: 10
  # @option opt [ActiveBookSortOrder] :sortOrder  Default: 'dateAdded'
  # @option opt [Direction]           :direction  Default: 'asc'
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-periodicals
  #
  def get_my_active_periodicals(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'myActivePeriodicals', **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          start:      String,
          limit:      Integer,
          sortOrder:  ActiveBookSortOrder,
          direction:  Direction,
        },
        reference_id: '_my-active-periodicals'
      }
    end

  # == POST /v2/myActivePeriodicals
  #
  # == 2.5.5. Add active periodical
  # Add a periodical to my active periodicals list.
  #
  # @param [String] bookshareId
  # @param [String] format
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-periodicals-add
  #
  def add_my_active_periodical(bookshareId:, format:, **opt)
    prm = encode_parameters(bookshareId: bookshareId, format: format)
    api(:post, 'myActivePeriodicals', **prm, **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          bookshareId: String,
          format:      String,
        },
        reference_id:  '_my-active-periodicals-add'
      }
    end

  # == DELETE /v2/myActivePeriodicals/{activeTitleId}
  #
  # == 2.5.6. Remove an active periodical
  # Remove one of the entries from my list of active periodicals.
  #
  # @param [String] activeTitleId
  # @param [Hash]   opt               Passed to #api.
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-periodicals-remove
  #
  def remove_my_active_periodical(activeTitleId:, **opt)
    api(:delete, 'myActivePeriodicals', activeTitleId, **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          activeTitleId: String,
        },
        reference_id:    '_my-active-periodicals-remove'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myActiveBooksProfile
  #
  # == 2.5.7. Get my active books profile
  # Get the current user’s choices of properties that guide how titles are
  # added by the system to a user’s active books list.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [ApiActiveBookProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-book-profile-get
  #
  def get_my_active_books_profile(**opt)
    api(:get, 'myActiveBooksProfile', **opt)
    ApiActiveBookProfile.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_my-active-book-profile-get'
      }
    end

  # == PUT /v2/myActiveBooksProfile
  #
  # == 2.5.8. Update my active books profile
  # Update the current user’s choices of properties that guide how titles are
  # added by the system to a user’s active books list.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [Boolean] :useRecommendations
  # @option opt [Boolean] :useRequestList
  # @option opt [Integer] :maxContributions
  #
  # @return [ApiActiveBookProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-book-profile-put
  #
  def update_my_active_books_profile(**opt)
    opt = get_parameters(__method__, **opt)
    api(:put, 'myActiveBooksProfile', **opt)
    ApiActiveBookProfile.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        optional: {
          useRecommendations: Boolean,
          useRequestList:     Boolean,
          maxContributions:   Integer,
        },
        reference_id:         '_my-active-book-profile-put'
      }
    end

end

__loading_end(__FILE__)
