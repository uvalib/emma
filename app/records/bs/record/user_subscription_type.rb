# app/records/bs/record/user_subscription_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::UserSubscriptionType
#
# @attr [String] description
# @attr [String] name
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_subscription_type
#
class Bs::Record::UserSubscriptionType < Bs::Api::Record

  schema do
    attribute :description, String
    attribute :name,        String
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
    name.to_s
  end

end

__loading_end(__FILE__)