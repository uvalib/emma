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
# @see https://apidocs.bookshare.org/reference/index.html#_user_subscription
#
# NOTE: This duplicates:
# @see Bs::Record::UserSubscription
#
#--
# noinspection DuplicatedCode
#++
class Bs::Message::UserSubscription < Bs::Api::Message

  include Bs::Shared::LinkMethods

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

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    userSubscriptionType.to_s
  end

  # Return the unique identifier for the represented item.
  #
  # @return [String]
  #
  def identifier
    subscriptionId.to_s
  end

end

__loading_end(__FILE__)
