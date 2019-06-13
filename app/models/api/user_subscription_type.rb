# app/models/api/user_subscription_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::UserSubscriptionType
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_subscription_type
#
class Api::UserSubscriptionType < Api::Record::Base

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
