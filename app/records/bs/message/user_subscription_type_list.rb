# app/records/bs/message/user_subscription_type_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSubscriptionTypeList
#
# @attr [Array<Bs::Record::Link>]                 links
# @attr [Array<Bs::Record::UserSubscriptionType>] userSubscriptionTypes
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_subscription_type_list
#
class Bs::Message::UserSubscriptionTypeList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many :links,                 Bs::Record::Link
    has_many :userSubscriptionTypes, Bs::Record::UserSubscriptionType
  end

end

__loading_end(__FILE__)
