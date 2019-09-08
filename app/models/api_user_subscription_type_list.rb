# app/models/api_user_subscription_type_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiUserSubscriptionTypeList
#
# @attr [Array<Api::Link>]                 links
# @attr [Array<Api::UserSubscriptionType>] userSubscriptionTypes
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_subscription_type_list
#
class ApiUserSubscriptionTypeList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many :links,                 Api::Link
    has_many :userSubscriptionTypes, Api::UserSubscriptionType
  end

end

__loading_end(__FILE__)
