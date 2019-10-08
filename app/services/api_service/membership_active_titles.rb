# app/services/api_service/membership_active_titles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::MembershipActiveTitles
#
# == Usage Notes
#
# === From API section 2.12 (Membership Assistant - Active Titles):
# Membership Assistant users are able to manage active titles on behalf of a
# given user account.
#
# noinspection RubyParameterNamingConvention, RubyLocalVariableNamingConvention
module ApiService::MembershipActiveTitles

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  MEMBERSHIP_ACTIVE_TITLES_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  MEMBERSHIP_ACTIVE_TITLES_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/activeBooks
  #
  # == 2.12.1. Get active books for a user
  # Get a list of active books for a specific user that are ready to read.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Optional API URL parameters.
  #
  # @option opt [String]            :start
  # @option opt [Integer]           :limit      Default: 10
  # @option opt [AssignedSortOrder] :sortOrder  Default: 'title'
  # @option opt [Direction]         :direction  Default: 'asc'
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-books
  #
  def get_active_books(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:get, 'accounts', userIdentifier, 'activeBooks', **opt)
    ApiActiveBookList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        optional: {
          start:          String,
          limit:          Integer,
          sortOrder:      AssignedSortOrder,
          direction:      Direction,
        },
        reference_id:     '_user-active-books'
      }
    end

  # == POST /v2/accounts/{userIdentifier}/activeBooks
  #
  # == 2.12.2. Add active book for a user
  # Add a book to a specific user’s active books list.
  #
  # @param [User, String, nil] user         Default: @user
  # @param [String]            bookshareId
  # @param [String]            format
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-books-add
  #
  def create_active_book(user: @user, bookshareId:, format:)
    userIdentifier = name_of(user)
    opt = { bookshareId: bookshareId, format: format }
    api(:post, 'accounts', userIdentifier, 'activeBooks', **opt)
    ApiActiveBookList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          bookshareId:    String,
          format:         String,
        },
        reference_id:     '_user-active-books-add'
      }
    end

  # == DELETE /v2/accounts/{userIdentifier}/activeBooks/{activeTitleId}
  #
  # == 2.12.3. Remove an active book
  # Remove one of the entries from a specific user’s list of active books.
  #
  # @param [User, String, nil] user           Default: @user
  # @param [String]            activeTitleId
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-books-remove
  #
  def delete_active_book(user: @user, activeTitleId:)
    userIdentifier = name_of(user)
    api(:delete, 'accounts', userIdentifier, 'activeBooks', activeTitleId)
    ApiActiveBookList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          activeTitleId:  String,
        },
        reference_id:     '_user-active-books-remove'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/activePeriodicals
  #
  # == 2.12.4. Get active periodicals for a user
  # Get a list of active periodicals for a specific user that are ready to
  # read.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Optional API URL parameters.
  #
  # @option opt [String]            :start
  # @option opt [Integer]           :limit      Default: 10
  # @option opt [AssignedSortOrder] :sortOrder  Default: 'title'
  # @option opt [Direction]         :direction  Default: 'asc'
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-periodicals
  #
  def get_active_periodicals(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:get, 'accounts', userIdentifier, 'activePeriodicals', **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        optional: {
          start:          String,
          limit:          Integer,
          sortOrder:      AssignedSortOrder,
          direction:      Direction,
        },
        reference_id:     '_user-active-periodicals'
      }
    end

  # == POST /v2/accounts/{userIdentifier}/activePeriodicals
  #
  # == 2.12.5. Add active periodical for a user
  # Add a periodical to a specific user’s active periodicals list.
  #
  # @param [User, String, nil] user         Default: @user
  # @param [String]            bookshareId
  # @param [String]            format
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-periodicals-add
  #
  def create_active_periodical(user: @user, bookshareId:, format:)
    userIdentifier = name_of(user)
    opt = { bookshareId: bookshareId, format: format }
    api(:post, 'accounts', userIdentifier, 'activePeriodicals', **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          bookshareId:    String,
          format:         String,
        },
        reference_id:     '_user-active-periodicals-add'
      }
    end

  # == DELETE /v2/accounts/{userIdentifier}/activePeriodicals/{activeTitleId}
  #
  # == 2.12.6. Remove an active periodical
  # Remove one of the entries from a specific user’s list of active
  # periodicals.
  #
  # @param [User, String, nil] user           Default: @user
  # @param [String]            activeTitleId
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-periodicals-remove
  #
  def delete_active_periodical(user: @user, activeTitleId:)
    user = name_of(user)
    api(:delete, 'accounts', user, 'activePeriodicals', activeTitleId)
    ApiActivePeriodicalList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          activeTitleId:  String,
        },
        reference_id:     '_user-active-periodicals-remove'
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/activeBooksProfile
  #
  # == 2.12.7. Get active books profile
  # Get a particular user’s choices of properties that guide how titles are
  # added by the system to a user’s active books list.
  #
  # @param [User, String, nil] user   Default: @user
  #
  # @return [ApiActiveBookProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-active-book-profile
  #
  def get_active_books_profile(user: @user)
    userIdentifier = name_of(user)
    api(:get, 'accounts', userIdentifier, 'activeBooksProfile')
    ApiActiveBookProfile.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_id:     '_get-active-book-profile'
      }
    end

  # == PUT /v2/accounts/{userIdentifier}/activeBooksProfile
  #
  # == 2.12.8. Update active books profile
  # Update a particular user’s choices of properties that guide how titles are
  # added by the system to a user’s active books list.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Optional API URL parameters.
  #
  # @option opt [Boolean] :useRecommendations
  # @option opt [Boolean] :useRequestList
  # @option opt [Integer] :maxContributions
  #
  # @return [ApiActiveBookProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-active-book-profile
  #
  def update_active_books_profile(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:put, 'accounts', userIdentifier, 'activeBooksProfile', **opt)
    ApiActiveBookProfile.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:               :userIdentifier,
        },
        required: {
          userIdentifier:     String,
        },
        optional: {
          useRecommendations: Boolean,
          useRequestList:     Boolean,
          maxContributions:   Integer,
        },
        reference_id:         '_put-active-book-profile'
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
    response_table = MEMBERSHIP_ACTIVE_TITLES_SEND_RESPONSE
    message_table  = MEMBERSHIP_ACTIVE_TITLES_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::AccountError, message
  end

end

__loading_end(__FILE__)
