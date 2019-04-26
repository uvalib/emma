# app/models/api/user_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'
require 'api/download_timeframe'
require 'api/link'
require 'api/user_subscription_type'

# Api::UserSubscription
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_subscription
#
class Api::UserSubscription < Api::Record::Base

  schema do
    attribute :downloadTimeframe,    DownloadTimeframe
    attribute :endDate,              String
    has_many  :links,                Link
    attribute :notes,                String
    attribute :numBooksAllowed,      Integer
    attribute :startDate,            String
    attribute :subscriptionId,       String
    attribute :userSubscriptionType, UserSubscriptionType
  end

end

__loading_end(__FILE__)
