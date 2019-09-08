# app/models/api/usage_restriction.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::UsageRestriction
#
# @attr [String] name
# @attr [String] usageRestrictionId
#
# @see https://apidocs.bookshare.org/reference/index.html#_usage_restriction
#
class Api::UsageRestriction < Api::Record::Base

  schema do
    attribute :name,               String
    attribute :usageRestrictionId, String
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

  # Return the unique identifier for this item.
  #
  # @return [String]
  #
  def identifier
    usageRestrictionId.to_s
  end

end

__loading_end(__FILE__)
