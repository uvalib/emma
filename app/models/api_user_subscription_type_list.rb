# app/models/api_user_subscription_type_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/link'
require_relative 'api/user_subscription_type'

# ApiUserSubscriptionTypeList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_subscription_type_list
#
class ApiUserSubscriptionTypeList < Api::Message

  schema do
    has_many :links,                 Api::Link
    has_many :userSubscriptionTypes, Api::UserSubscriptionType
  end

end

__loading_end(__FILE__)
