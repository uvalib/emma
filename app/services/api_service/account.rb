# app/services/api_service/account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Account
#
# noinspection RubyParameterNamingConvention
module ApiService::Account

  include ApiService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>String}]
  ACCOUNT_SEND_MESSAGE = {

    # TODO: e.g.:
    no_items:      'There were no items to request',
    failed:        'Unable to request items right now',

  }.reverse_merge(API_SEND_MESSAGE).freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  ACCOUNT_SEND_RESPONSE = {

    # TODO: e.g.:
    no_items:       'no items',
    failed:         nil

  }.reverse_merge(API_SEND_RESPONSE).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/me
  # Request basic information about the current user.
  #
  # @return [ApiUserIdentity]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_me
  #
  def get_user_identity(*)
    api(:get, 'me')
    ApiUserIdentity.new(response, error: exception)
  end

  # == GET /v2/myaccount
  # Get an account summary of the current user.
  #
  # @return [ApiMyAccountSummary]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myaccount-summary
  #
  def get_my_account(*)
    api(:get, 'myaccount')
    ApiMyAccountSummary.new(response, error: exception)
  end

  # == GET /v2/myaccount/history
  # Get a listing of downloads made by the current user.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [Integer]          :limit
  # @option opt [HistorySortOrder] :sortOrder   Default: 'title'
  # @option opt [Direction2]       :direction   Default: 'desc'
  #
  # @return [ApiTitleDownloadList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myaccount-downloads
  #
  def get_my_download_history(**opt)
    validate_parameters(__method__, opt)
    api(:get, 'myaccount', 'history', **opt)
    ApiTitleDownloadList.new(response, error: exception)
  end

  # == GET /v2/myaccount/preferences
  # Get the account preferences associated with the current user.
  #
  # @return [ApiMyAccountPreferences]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-myaccount-preferences
  #
  def get_my_preferences(*)
    api(:get, 'myaccount', 'preferences')
    ApiMyAccountPreferences.new(response, error: exception)
  end

  # == PUT /v2/myaccount/preferences
  # Update the account preferences associated with the current user.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [Boolean]       :allowAdultContent
  # @option opt [Boolean]       :showAllBooks           Default: *false*
  # @option opt [IsoLanguage]   :language
  # @option opt [FormatType]    :format
  # @option opt [FormatType]    :fmt                    Alias for :format
  # @option opt [BrailleGrade]  :brailleGrade
  # @option opt [BrailleFormat] :brailleFormat
  # @option opt [Boolean]       :useUeb                 Default: *false*
  # @option opt [Integer]       :brailleCellLineWidth
  #
  # @return [ApiMyAccountPreferences]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-myaccount-preferences
  #
  def update_my_preferences(**opt)
    validate_parameters(__method__, opt)
    api(:put, 'myaccount', 'preferences', **opt)
    ApiMyAccountPreferences.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}
  # Get details about the specified user account.
  #
  # @param [User, String, nil] user   Default: @user
  #
  # @return [ApiUserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-useraccount-search
  #
  def get_account(user: @user)
    username = name_of(user)
    api(:get, 'accounts', username)
    ApiUserAccount.new(response, error: exception)
  end

  # == PUT /v2/accounts/{userIdentifier}
  # Update an existing user account.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
  #
  # @option opt [String]      :firstName
  # @option opt [String]      :lastName
  # @option opt [String]      :phoneNumber
  # @option opt [String]      :emailAddress
  # @option opt [String]      :address1
  # @option opt [String]      :address2
  # @option opt [String]      :city
  # @option opt [String]      :state
  # @option opt [String]      :country
  # @option opt [String]      :postalCode
  # @option opt [String]      :guardianFirstName
  # @option opt [String]      :guardianLastName
  # @option opt [String]      :dateOfBirth
  # @option opt [IsoLanguage] :language
  # @option opt [Boolean]     :allowAdultContent
  # @option opt [SiteType]    :site
  # @option opt [RoleType]    :role
  # @option opt [String]      :password
  #
  # @return [ApiUserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_update-useraccount
  #
  def update_account(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:put, 'accounts', username, **opt)
    ApiUserAccount.new(response, error: exception)
  end

  # == POST /v2/accounts
  # Create a new user account.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String]      :firstName          *REQUIRED*
  # @option opt [String]      :lastName           *REQUIRED*
  # @option opt [String]      :phoneNumber
  # @option opt [String]      :emailAddress       *REQUIRED*
  # @option opt [String]      :address1           *REQUIRED*
  # @option opt [String]      :address2
  # @option opt [String]      :city               *REQUIRED*
  # @option opt [String]      :state
  # @option opt [String]      :country            *REQUIRED*
  # @option opt [String]      :postalCode         *REQUIRED*
  # @option opt [String]      :guardianFirstName
  # @option opt [String]      :guardianLastName
  # @option opt [String]      :dateOfBirth
  # @option opt [IsoLanguage] :language
  # @option opt [Boolean]     :allowAdultContent
  # @option opt [SiteType]    :site
  # @option opt [RoleType]    :role
  # @option opt [String]      :password
  #
  # @return [ApiUserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-useraccount
  #
  def create_account(**opt)
    validate_parameters(__method__, opt)
    api(:post, 'accounts', **opt)
    ApiUserAccount.new(response, error: exception)
  end

  # == PUT /v2/accounts/{userIdentifier}/password
  # Update the password for an existing user.
  #
  # @param [User, String, nil] user       Default: @user
  # @param [String]            password
  #
  # @return [ApiStatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_update-membership-password
  #
  def update_account_password(user: @user, password:)
    username = name_of(user)
    api(:put, 'accounts', username, 'password', password: password)
    ApiStatusModel.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myAssignedTitles
  # Get the titles assigned to the current user (organization member).
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String]              :start
  # @option opt [Integer]             :limit        Default: 10
  # @option opt [MyAssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]           :direction    Default: 'asc'
  #
  # @return [ApiTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-assigned-titles
  #
  def get_my_assigned_titles(**opt)
    validate_parameters(__method__, opt)
    api(:get, 'myAssignedTitles', **opt)
    ApiTitleMetadataSummaryList.new(response, error: exception)
  end

  # == GET /v2/assignedTitles/{userIdentifier}
  # Get a list of titles assigned to the specified organization member.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
  #
  # @option opt [String]            :start
  # @option opt [Integer]           :limit        Default: 10
  # @option opt [AssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]         :direction    Default: 'asc'
  #
  # @return [ApiAssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_titles-assigned-member
  #
  def get_assigned_titles(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:get, 'assignedTitles', username, **opt)
    ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
  end

  # == POST /v2/assignedTitles/{userIdentifier}
  # Assign a title to the specified organization member.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
  #
  # @option opt [String]    :bookshareId          *REQUIRED*
  #
  # @return [ApiAssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-assign
  #
  def create_assigned_title(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:post, 'assignedTitles', username, **opt)
    ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
  end

  # == DELETE /v2/assignedTitles/{userIdentifier}/{bookshareId}
  # Assign a title to the specified organization member.
  #
  # @param [User, String, nil] user         Default: @user
  # @param [String]            bookshareId
  #
  # @return [ApiAssignedTitleMetadataSummaryList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_title-unassign
  #
  def remove_assigned_title(user: @user, bookshareId:)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:delete, 'assignedTitles', username, bookshareId)
    ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myActiveBooks
  # Get a list of my active books that are ready to read.
  #
  # @param [Hash] opt                 API URL parameters
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
    validate_parameters(__method__, opt)
    api(:get, 'myActiveBooks', **opt)
    ApiActiveBookList.new(response, error: exception)
  end

  # == POST /v2/myActiveBooks
  # Add a book to my active books list.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String] :bookshareId             *REQUIRED*
  # @option opt [String] :format                  *REQUIRED*
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-books-add
  #
  def add_my_active_book(**opt)
    validate_parameters(__method__, opt)
    api(:post, 'myActiveBooks', **opt)
    ApiActiveBookList.new(response, error: exception)
  end

  # == DELETE /v2/myActiveBooks/{activeTitleId}
  # Remove one of the entries from my list of active books.
  #
  # @param [String] activeTitleId
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-books-remove
  #
  def remove_my_active_book(activeTitleId:)
    validate_parameters(__method__, opt)
    api(:delete, 'myActiveBooks', activeTitleId)
    ApiActiveBookList.new(response, error: exception)
  end

  # == GET /v2/accounts/{userIdentifier}/activeBooks
  # Get a list of active books for a specific user that are ready to read.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
  #
  # @option opt [String]            :start
  # @option opt [Integer]           :limit        Default: 10
  # @option opt [AssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]         :direction    Default: 'asc'
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-books
  #
  def get_active_books(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:get, 'accounts', username, 'activeBooks', **opt)
    ApiActiveBookList.new(response, error: exception)
  end

  # == POST /v2/accounts/{userIdentifier}/activeBooks
  # Add a book to a specific user’s active books list.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
  #
  # @option opt [String] :bookshareId             *REQUIRED*
  # @option opt [String] :format                  *REQUIRED*
  #
  # @return [ApiActiveBookList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-books-add
  #
  def create_active_book(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:post, 'accounts', username, 'activeBooks', **opt)
    ApiActiveBookList.new(response, error: exception)
  end

  # == DELETE /v2/accounts/{userIdentifier}/activeBooks/{activeTitleId}
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
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:delete, 'accounts', username, 'activeBooks', activeTitleId)
    ApiActiveBookList.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/myActivePeriodicals
  # Get a list of my active periodicals that are ready to read.
  #
  # @param [Hash] opt                 API URL parameters
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
    validate_parameters(__method__, opt)
    api(:get, 'myActivePeriodicals', **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end

  # == POST /v2/myActivePeriodicals
  # Add a periodical to my active periodicals list.
  #
  # @param [Hash] opt                 API URL parameters
  #
  # @option opt [String] :bookshareId             *REQUIRED*
  # @option opt [String] :format                  *REQUIRED*
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-periodicals-add
  #
  def add_my_active_periodical(**opt)
    validate_parameters(__method__, opt)
    api(:post, 'myActivePeriodicals', **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end

  # == DELETE /v2/myActivePeriodicals/{activeTitleId}
  # Remove one of the entries from my list of active periodicals.
  #
  # @param [String] activeTitleId
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_my-active-periodicals-remove
  #
  def remove_my_active_periodical(activeTitleId:)
    validate_parameters(__method__, opt)
    api(:delete, 'myActivePeriodicals', activeTitleId)
    ApiActivePeriodicalList.new(response, error: exception)
  end

  # == GET /v2/accounts/{userIdentifier}/activePeriodicals
  # Get a list of active periodicals for a specific user that are ready to
  # read.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
  #
  # @option opt [String]            :start
  # @option opt [Integer]           :limit        Default: 10
  # @option opt [AssignedSortOrder] :sortOrder    Default: 'title'
  # @option opt [Direction]         :direction    Default: 'asc'
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-periodicals
  #
  def get_active_periodicals(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:get, 'accounts', username, 'activePeriodicals', **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end

  # == POST /v2/accounts/{userIdentifier}/activePeriodicals
  # Add a periodical to a specific user’s active periodicals list.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
  #
  # @option opt [String] :bookshareId             *REQUIRED*
  # @option opt [String] :format                  *REQUIRED*
  #
  # @return [ApiActivePeriodicalList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_user-active-periodicals-add
  #
  def create_active_periodical(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:post, 'accounts', username, 'activePeriodicals', **opt)
    ApiActivePeriodicalList.new(response, error: exception)
  end

  # == DELETE /v2/accounts/{userIdentifier}/activePeriodicals/{activeTitleId}
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
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:delete, 'accounts', username, 'activePeriodicals', activeTitleId)
    ApiActivePeriodicalList.new(response, error: exception)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/activeBooksProfile
  # Get a particular user’s choices of properties that guide how titles are
  # added by the system to a user’s active books list.
  #
  # @param [User, String, nil] user   Default: @user
  #
  # @return [ApiActiveBookProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-active-book-profile
  #
  def get_active_books_profile(user: @user, **opt)
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:get, 'accounts', username, 'activeBooksProfile', **opt)
    ApiActiveBookProfile.new(response, error: exception)
  end

  # == PUT /v2/accounts/{userIdentifier}/activeBooksProfile
  # Update a particular user’s choices of properties that guide how titles are
  # added by the system to a user’s active books list.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    API URL parameters
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
    validate_parameters(__method__, opt)
    username = name_of(user)
    api(:put, 'accounts', username, 'activeBooksProfile', **opt)
    ApiActiveBookProfile.new(response, error: exception)
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
    response_table = ACCOUNT_SEND_RESPONSE
    message_table  = ACCOUNT_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::AccountError, message
  end

end

__loading_end(__FILE__)
