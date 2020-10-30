# app/records/bs/record/usage_restriction.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::UsageRestriction
#
# @attr [String] name
# @attr [String] usageRestrictionId
#
# @see https://apidocs.bookshare.org/reference/index.html#_usage_restriction
#
class Bs::Record::UsageRestriction < Bs::Api::Record

  schema do
    has_one   :name
    has_one   :usageRestrictionId
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
