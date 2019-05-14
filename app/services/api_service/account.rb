# app/services/api_service/account.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  module Account

    include Common

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

    # get_user_identity
    #
    # @return [ApiUserIdentity]
    #
    def get_user_identity(*)
      api(:get, 'me')
      data = response&.body&.presence
      ApiUserIdentity.new(data, error: @exception)
    end

    # get_my_account
    #
    # @return [ApiMyAccountSummary]
    #
    def get_my_account(*)
      api(:get, 'myaccount')
      data = response&.body&.presence
      ApiMyAccountSummary.new(data, error: @exception)
    end

    # get_my_download_history
    #
    # @param [Hash, nil] opt
    #
    # @option opt [Object] :limit
    # @option opt [Object] :sortOrder
    # @option opt [Object] :direction
    #
    # @return [ApiTitleDownloadList]
    #
    def get_my_download_history(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'myaccount', 'history', opt)
      data = response&.body&.presence
      ApiTitleDownloadList.new(data, error: @exception)
    end

    # get_my_preferences
    #
    # @return [ApiMyAccountPreferences]
    #
    def get_my_preferences(*)
      api(:get, 'myaccount', 'preferences')
      data = response&.body&.presence
      ApiMyAccountPreferences.new(data, error: @exception)
    end

    # update_my_preferences
    #
    # @param [Hash, nil] opt
    #
    # @option opt [Boolean]       :allowAdultContent
    # @option opt [Boolean]       :showAllBooks           Default: *false*
    # @option opt [String]        :language
    # @option opt [FormatType]    :format
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
      data = response&.body&.presence
      ApiMyAccountPreferences.new(data, error: @exception)
    end

    # create_account
    #
    # @param [Hash, nil] opt
    #
    # @return [ApiUserAccount]
    #
    def create_account(**opt)
      validate_parameters(__method__, opt)
      api(:post, 'accounts', opt)
      data = response&.body&.presence
      ApiUserAccount.new(data, error: @exception)
    end

    # get_account
    #
    # @param [User, String, nil] user       Default: @user
    #
    # @return [ApiUserAccount]
    #
    def get_account(user: @user)
      username = get_username(user)
      api(:get, 'accounts', username)
      data = response&.body&.presence
      ApiUserAccount.new(data, error: @exception)
    end

    # update_account_password
    #
    # @param [User, String, nil] user       Default: @user
    # @param [String]            password
    #
    # @return [ApiStatusModel]
    #
    def update_account_password(user: @user, password:)
      username = get_username(user)
      api(:put, 'accounts', username, 'password', password: password)
      data = response&.body&.presence
      ApiStatusModel.new(data, error: @exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_my_assigned_titles
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]    :start
    # @option opt [Integer]   :limit        Default: 10
    # @option opt [SortOrder] :sortOrder    Default: 'title'
    # @option opt [Direction] :direction    Default: 'asc'
    #
    # @return [ApiTitleMetadataSummaryList]
    #
    def get_my_assigned_titles(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'myAssignedTitles', opt)
      data = response&.body&.presence
      ApiTitleMetadataSummaryList.new(data, error: @exception)
    end

    # get_assigned_titles
    #
    # @param [User, String, nil] user       Default: @user
    # @param [Hash, nil]         opt
    #
    # @option opt [String]    :start
    # @option opt [Integer]   :limit        Default: 10
    # @option opt [SortOrder] :sortOrder    Default: 'title'
    # @option opt [Direction] :direction    Default: 'asc'
    #
    # @return [ApiAssignedTitleMetadataSummaryList]
    #
    def get_assigned_titles(user: @user, **opt)
      validate_parameters(__method__, opt)
      username = get_username(user)
      api(:get, 'assignedTitles', username, opt)
      data = response&.body&.presence
      ApiAssignedTitleMetadataSummaryList.new(data, error: @exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_organization_members
    #
    # @param [Hash, nil] opt
    #
    # @option opt [String]    :start
    # @option opt [Integer]   :limit        Default: 10
    # @option opt [SortOrder] :sortOrder    Default: 'lastName'
    # @option opt [Direction] :direction    Default: 'asc'
    #
    # @return [ApiUserAccountList]
    #
    def get_organization_members(**opt)
      validate_parameters(__method__, opt)
      api(:get, 'myOrganization', 'members', opt)
      data = response&.body&.presence
      ApiUserAccountList.new(data, error: @exception)
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

  end

end

__loading_end(__FILE__)
