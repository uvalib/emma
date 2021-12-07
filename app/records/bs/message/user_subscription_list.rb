# app/records/bs/message/user_subscription_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSubscriptionList
#
# @attr [Array<BsAllowsType>]                 allows
# @attr [Integer]                             limit
# @attr [Array<Bs::Record::Link>]             links
# @attr [String]                              next
# @attr [Integer]                             totalResults
# @attr [Array<Bs::Record::UserSubscription>] userSubscriptions
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_subscription_list
#
class Bs::Message::UserSubscriptionList < Bs::Api::Message

  include Bs::Shared::CollectionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Bs::Record::UserSubscription

  schema do
    has_many  :allows,            BsAllowsType
    has_one   :limit,             Integer
    has_many  :links,             Bs::Record::Link
    has_one   :next
    has_one   :totalResults,      Integer
    has_many  :userSubscriptions, LIST_ELEMENT
  end

end

__loading_end(__FILE__)
