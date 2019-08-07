# app/models/api_user_subscription_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/user_subscription'

# ApiUserSubscriptionList
#
# @attr [Array<AllowsType>]            allows
# @attr [Integer]                      limit
# @attr [Array<Api::Link>]             links
# @attr [String]                       next
# @attr [Integer]                      totalResults
# @attr [Array<Api::UserSubscription>] userSubscriptions
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_subscription_list
#
class ApiUserSubscriptionList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many  :allows,            AllowsType
    attribute :limit,             Integer
    has_many  :links,             Api::Link
    attribute :next,              String
    attribute :totalResults,      Integer
    has_many  :userSubscriptions, Api::UserSubscription
  end

end

__loading_end(__FILE__)
