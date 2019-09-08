# app/models/api_user_subscription.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiUserSubscription
#
# @attr [Api::DownloadTimeframe]    downloadTimeframe
# @attr [String]                    endDate
# @attr [Array<Api::Link>]          links
# @attr [String]                    notes
# @attr [Integer]                   numBooksAllowed
# @attr [String]                    startDate
# @attr [String]                    subscriptionId
# @attr [Api::UserSubscriptionType] userSubscriptionType
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_subscription
#
# NOTE: This duplicates:
# @see Api::UserSubscription
#
# noinspection DuplicatedCode
class ApiUserSubscription < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_one   :downloadTimeframe,    Api::DownloadTimeframe
    attribute :endDate,              String
    has_many  :links,                Api::Link
    attribute :notes,                String
    attribute :numBooksAllowed,      Integer
    attribute :startDate,            String
    attribute :subscriptionId,       String
    has_one   :userSubscriptionType, Api::UserSubscriptionType
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
