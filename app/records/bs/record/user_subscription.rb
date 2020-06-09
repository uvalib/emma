# app/records/bs/record/user_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::UserSubscription
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
# @see Bs::Message::UserSubscription
#
#--
# noinspection DuplicatedCode
#++
class Bs::Record::UserSubscription < Bs::Api::Record

  include Bs::Shared::LinkMethods

  schema do
    has_one   :downloadTimeframe,    Bs::Record::DownloadTimeframe
    attribute :endDate,              IsoDate
    has_many  :links,                Bs::Record::Link
    attribute :notes,                String
    attribute :numBooksAllowed,      Integer
    attribute :startDate,            IsoDate
    attribute :subscriptionId,       String
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
