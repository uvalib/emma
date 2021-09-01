# app/records/bs/message/user_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserSubscription
#
# @attr [Bs::Record::DownloadTimeframe]    downloadTimeframe
# @attr [IsoDate]                          endDate
# @attr [Array<Bs::Record::Link>]          links
# @attr [String]                           notes
# @attr [Integer]                          numBooksAllowed
# @attr [IsoDate]                          startDate
# @attr [String]                           subscriptionId
# @attr [Bs::Record::UserSubscriptionType] userSubscriptionType
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_subscription
#
# @see Bs::Record::UserSubscription (duplicate schema)
#
class Bs::Message::UserSubscription < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::SubscriptionMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :downloadTimeframe,    Bs::Record::DownloadTimeframe
    has_one   :endDate,              IsoDate
    has_many  :links,                Bs::Record::Link
    has_one   :notes
    has_one   :numBooksAllowed,      Integer
    has_one   :startDate,            IsoDate
    has_one   :subscriptionId
    has_one   :userSubscriptionType, Bs::Record::UserSubscriptionType
  end

end

__loading_end(__FILE__)
