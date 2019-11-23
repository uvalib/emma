# app/records/bs/message/user_subscription_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSubscriptionList
#
# @attr [Array<AllowsType>]                   allows
# @attr [Integer]                             limit
# @attr [Array<Bs::Record::Link>]             links
# @attr [String]                              next
# @attr [Integer]                             totalResults
# @attr [Array<Bs::Record::UserSubscription>] userSubscriptions
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_subscription_list
#
class Bs::Message::UserSubscriptionList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  schema do
    has_many  :allows,            AllowsType
    attribute :limit,             Integer
    has_many  :links,             Bs::Record::Link
    attribute :next,              String
    attribute :totalResults,      Integer
    has_many  :userSubscriptions, Bs::Record::UserSubscription
  end

end

__loading_end(__FILE__)
