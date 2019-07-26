# app/services/api_service/account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  # ApiService::Account
  #
  module Account

    include Common

    # =========================================================================
    # :section:
    # =========================================================================

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

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # == GET /v2/me
    # Request basic information about the current user.
    #
    # @return [ApiUserIdentity]
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
    def get_my_account(*)
      api(:get, 'myaccount')
      ApiMyAccountSummary.new(response, error: exception)
    end

    # == GET /v2/myaccount/history
    # Get a listing of downloads made by the current user.
    #
    # @param [Hash, nil] opt
    #
    # @option opt [Integer]          :limit
    # @option opt [HistorySortOrder] :sortOrder   Default: 'title'
    # @option opt [Direction2]       :direction   Default: 'desc'
    #
    # @return [ApiTitleDownloadList]
    #
    def get_my_download_history(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'myaccount', 'history', opt)
      ApiTitleDownloadList.new(response, error: exception)
    end

    # == GET /v2/myaccount/preferences
    # Get the account preferences associated with the current user.
    #
    # @return [ApiMyAccountPreferences]
    #
    def get_my_preferences(*)
      api(:get, 'myaccount', 'preferences')
      ApiMyAccountPreferences.new(response, error: exception)
    end

    # == PUT /v2/myaccount/preferences
    # Update the account preferences associated with the current user.
    #
    # @param [Hash, nil] opt
    #
    # @option opt [Boolean]       :allowAdultContent
    # @option opt [Boolean]       :showAllBooks           Default: *false*
    # @option opt [String]        :language
    # @option opt [FormatType]    :format
    # @option opt [FormatType]    :fmt                    Alias for :format
    # @option opt [BrailleGrade]  :brailleGrade
    # @option opt [BrailleFormat] :brailleFormat
    # @option opt [Boolean]       :useUeb                 Default: *false*
    # @option opt [Integer]       :brailleCellLineWidth
    #
    # @return [ApiMyAccountPreferences]
    #
    def update_my_preferences(**opt)
      validate_parameters(__method__, opt)
      api(:put, 'myaccount', 'preferences', opt)
      ApiMyAccountPreferences.new(response, error: exception)
    end

    # == POST /v2/accounts
    # Create a new user account.
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]   :firstName          *REQUIRED*
    # @option opt [String]   :lastName           *REQUIRED*
    # @option opt [String]   :phoneNumber
    # @option opt [String]   :emailAddress       *REQUIRED*
    # @option opt [String]   :address1           *REQUIRED*
    # @option opt [String]   :address2
    # @option opt [String]   :city               *REQUIRED*
    # @option opt [String]   :state
    # @option opt [String]   :country            *REQUIRED*
    # @option opt [String]   :postalCode         *REQUIRED*
    # @option opt [String]   :guardianFirstName
    # @option opt [String]   :guardianLastName
    # @option opt [String]   :dateOfBirth
    # @option opt [String]   :language
    # @option opt [Boolean]  :allowAdultContent
    # @option opt [SiteType] :site
    # @option opt [RoleType] :role
    # @option opt [String]   :password
    #
    # @return [ApiUserAccount]
    #
    def create_account(**opt)
      validate_parameters(__method__, opt)
      api(:post, 'accounts', opt)
      ApiUserAccount.new(response, error: exception)
    end

    # == GET /v2/accounts/:username
    # Get details about the specified user account.
    #
    # @param [User, String, nil] user       Default: @user
    #
    # @return [ApiUserAccount]
    #
    def get_account(user: @user)
      username = name_of(user)
      api(:get, 'accounts', username)
      ApiUserAccount.new(response, error: exception)
    end

    # == PUT /v2/accounts/:username/password
    # Update the password for an existing user.
    #
    # @param [User, String, nil] user       Default: @user
    # @param [String]            password
    #
    # @return [ApiStatusModel]
    #
    def update_account_password(user: @user, password:)
      username = name_of(user)
      api(:put, 'accounts', username, 'password', password: password)
      ApiStatusModel.new(response, error: exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # == GET /v2/myAssignedTitles
    # Get the titles assigned to the current user (organization member).
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]              :start
    # @option opt [Integer]             :limit        Default: 10
    # @option opt [MyAssignedSortOrder] :sortOrder    Default: 'title'
    # @option opt [Direction]           :direction    Default: 'asc'
    #
    # @return [ApiTitleMetadataSummaryList]
    #
    def get_my_assigned_titles(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'myAssignedTitles', opt)
      ApiTitleMetadataSummaryList.new(response, error: exception)
    end

    # == GET /v2/assignedTitles/:username
    # Get a list of titles assigned to the specified organization member.
    #
    # @param [User, String, nil] user       Default: @user
    # @param [Hash, nil]         opt
    #
    # @option opt [String]            :start
    # @option opt [Integer]           :limit        Default: 10
    # @option opt [AssignedSortOrder] :sortOrder    Default: 'title'
    # @option opt [Direction]         :direction    Default: 'asc'
    #
    # @return [ApiAssignedTitleMetadataSummaryList]
    #
    def get_assigned_titles(user: @user, **opt)
      validate_parameters(__method__, opt)
      username = name_of(user)
      api(:get, 'assignedTitles', username, opt)
      ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
    end

    # == POST /v2/assignedTitles/:username
    # Assign a title to the specified organization member.
    #
    # @param [User, String, nil] user       Default: @user
    # @param [Hash, nil]         opt
    #
    # @option opt [String]    :bookshareId
    #
    # @return [ApiAssignedTitleMetadataSummaryList]
    #
    def create_assigned_title(user: @user, **opt)
      validate_parameters(__method__, opt)
      username = name_of(user)
      api(:post, 'assignedTitles', username, opt)
      ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
    end

    # == DELETE /v2/assignedTitles/:username
    # Assign a title to the specified organization member.
    #
    # @param [User, String, nil] user         Default: @user
    # @param [Hash, nil]         opt
    #
    # @option opt [String]    :bookshareId
    #
    # @return [ApiAssignedTitleMetadataSummaryList]
    #
    def remove_assigned_title(user: @user, **opt)
      validate_parameters(__method__, opt)
      username = name_of(user)
      api(:delete, 'assignedTitles', username, opt)
      ApiAssignedTitleMetadataSummaryList.new(response, error: exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # == GET /v2/myOrganization/members
    # Get a list of members of the current (sponsor) user's organization.
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]          :start
    # @option opt [Integer]         :limit        Default: 10
    # @option opt [MemberSortOrder] :sortOrder    Default: 'lastName'
    # @option opt [Direction]       :direction    Default: 'asc'
    #
    # @return [ApiUserAccountList]
    #
    def get_organization_members(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'myOrganization', 'members', opt)
      ApiUserAccountList.new(response, error: exception)
    end

    # == GET /v2/myOrganization/members/:id
    # Get a member of the current (sponsor) user's organization.
    #
    # NOTE: This is not a real Bookshare API call.
    #
    # @param [String] username
    #
    # @return [Api::UserAccount]
    #
    def get_organization_member(username:)
      all = get_organization_members(limit: :max)
      om  = all.userAccounts.find { |list| list.identifier == username }
      ApiUserAccount.new(om)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # raise_exception
    #
    # @param [Symbol, String] method  For log messages.
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

  end unless defined?(Account)

end

__loading_end(__FILE__)
