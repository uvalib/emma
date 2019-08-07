# app/services/api_service/subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  # ApiService::Subscription
  #
  # noinspection RubyParameterNamingConvention
  module Subscription

    include Common

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @type [Hash{Symbol=>String}]
    SUBSCRIPTION_SEND_MESSAGE = {

      # TODO: e.g.:
      no_items:      'There were no items to request',
      failed:        'Unable to request items right now',

    }.reverse_merge(API_SEND_MESSAGE).freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    SUBSCRIPTION_SEND_RESPONSE = {

      # TODO: e.g.:
      no_items:       'no items',
      failed:         nil

    }.reverse_merge(API_SEND_RESPONSE).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # == GET /v2/accounts/{userIdentifier}/subscriptions
    # Get the list of membership subscriptions for an existing user.
    #
    # @param [User, String, nil] user       Default: @user
    #
    # @return [ApiUserSubscriptionList]
    #
    def get_subscriptions(user: @user)
      username = name_of(user)
      api(:get, 'accounts', username, 'subscriptions')
      ApiUserSubscriptionList.new(response, error: exception)
    end

    # == POST /v2/accounts/{userIdentifier}/subscriptions
    # Create a new membership subscription for an existing user.
    #
    # @param [User, String, nil] user   Default: @user
    # @param [Hash]              opt    API URL parameters
    #
    # @option opt [IsoDay]    :startDate              *REQUIRED*
    # @option opt [IsoDay]    :endDate
    # @option opt [String]    :userSubscriptionType   *REQUIRED*
    # @option opt [Integer]   :numBooksAllowed
    # @option opt [Timeframe] :downloadTimeframe
    # @option opt [String]    :notes
    #
    # @return [ApiUserSubscription]
    #
    def create_subscription(user: @user, **opt)
      validate_parameters(__method__, opt)
      username = name_of(user)
      api(:post, 'accounts', username, 'subscriptions', **opt)
      ApiUserSubscription.new(response, error: exception)
    end

    # == GET /v2/accounts/{userIdentifier}/subscriptions/{subscriptionId}
    # Get the specified membership subscription for an existing user.
    #
    # @param [User, String, nil] user             Default: @user
    # @param [String]            subscriptionId
    #
    # @return [ApiUserSubscription]
    #
    def get_subscription(user: @user, subscriptionId:)
      username = name_of(user)
      api(:get, 'accounts', username, 'subscriptions', subscriptionId)
      ApiUserSubscription.new(response, error: exception)
    end

    # == PUT /v2/accounts/{userIdentifier}/subscriptions/{subscriptionId}
    # Update an existing membership subscription for an existing user.
    #
    # @param [User, String, nil] user             Default: @user
    # @param [String]            subscriptionId
    # @param [Hash]              opt              API URL parameters
    #
    # @option opt [IsoDay]    :startDate              *REQUIRED*
    # @option opt [IsoDay]    :endDate
    # @option opt [String]    :userSubscriptionType   *REQUIRED*
    # @option opt [Integer]   :numBooksAllowed
    # @option opt [Timeframe] :downloadTimeframe
    # @option opt [String]    :notes
    #
    # @return [ApiUserSubscription]
    #
    def update_subscription(user: @user, subscriptionId:, **opt)
      validate_parameters(__method__, opt)
      username = name_of(user)
      api(:put, 'accounts', username, 'subscriptions', subscriptionId, **opt)
      ApiUserSubscription.new(response, error: exception)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # == GET /v2/subscriptiontypes
    # Get the list of subscription types available to users of the Membership
    # Assistant’s site.
    #
    # @return [ApiUserSubscriptionTypeList]
    #
    def get_subscription_types(*)
      api(:get, 'subscriptiontypes')
      ApiUserSubscriptionTypeList.new(response, error: exception)
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
      response_table = SUBSCRIPTION_SEND_RESPONSE
      message_table  = SUBSCRIPTION_SEND_MESSAGE
      message = request_error_message(method, response_table, message_table)
      raise Api::SubscriptionError, message
    end

  end unless defined?(ApiService::Subscription)

end

__loading_end(__FILE__)
