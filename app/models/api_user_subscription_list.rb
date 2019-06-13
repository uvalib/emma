# app/models/api_user_subscription_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/link'
require_relative 'api/user_subscription'
require_relative 'api/common/sequence_methods'

# ApiUserSubscriptionList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_subscription_list
#
class ApiUserSubscriptionList < Api::Message

  schema do
    has_many  :allows,            AllowsType
    attribute :limit,             Integer
    has_many  :links,             Api::Link
    attribute :next,              String
    attribute :totalResults,      Integer
    has_many  :userSubscriptions, Api::UserSubscription
  end

  include Api::Common::SequenceMethods

end

__loading_end(__FILE__)
