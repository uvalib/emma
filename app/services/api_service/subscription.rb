# app/services/api_service/subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  module Subscription

    include Common

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

    # get_subscriptions
    #
    # @param [User, String, nil] user       Default: @user
    #
    # @return [ApiUserSubscriptionList]
    #
    def get_subscriptions(user: @user)
      username = name_of(user)
      api(:get, 'accounts', username, 'subscriptions')
      data = response&.body&.presence
      ApiUserSubscriptionList.new(data, error: @exception)
    end

    # create_subscription
    #
    # @param [User, String, nil] user       Default: @user
    # @param [Hash, nil]         opt
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
      api(:post, 'accounts', username, 'subscriptions', opt)
      data = response&.body&.presence
      ApiUserSubscription.new(data, error: @exception)
    end

    # get_subscription
    #
    # @param [User, String, nil] user             Default: @user
    # @param [String]            subscriptionId
    #
    # @return [ApiUserSubscription]
    #
    def get_subscription(user: @user, subscriptionId:)
      username = name_of(user)
      api(:get, 'accounts', username, 'subscriptions', subscriptionId)
      data = response&.body&.presence
      ApiUserSubscription.new(data, error: @exception)
    end

    # update_subscription
    #
    # @param [User, String, nil] user             Default: @user
    # @param [String]            subscriptionId
    # @param [Hash, nil]         opt
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
      api(:put, 'accounts', username, 'subscriptions', subscriptionId, opt)
      data = response&.body&.presence
      ApiUserSubscription.new(data, error: @exception)
    end

    # get_subscription_types
    #
    # @return [ApiUserSubscriptionTypeList]
    #
    def get_subscription_types(*)
      api(:get, 'subscriptiontypes')
      data = response&.body&.presence
      ApiUserSubscriptionTypeList.new(data, error: @exception)
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

  end

end

__loading_end(__FILE__)
