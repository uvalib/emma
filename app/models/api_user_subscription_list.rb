# app/models/api_user_subscription_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/link'
require 'api/user_subscription'

# ApiUserSubscriptionList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_subscription_list
#
class ApiUserSubscriptionList < Api::Message

  schema do
    has_many  :allows,            String
    attribute :limit,             Integer
    has_many  :links,             Link
    attribute :next,              String
    attribute :totalResults,      Integer
    has_many  :userSubscriptions, UserSubscription
  end

end

__loading_end(__FILE__)
