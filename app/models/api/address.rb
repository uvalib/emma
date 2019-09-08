# app/models/api/address.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::Address
#
# @attr [String] address1
# @attr [String] address2
# @attr [String] city
# @attr [String] postalCode
# @attr [String] state
#
# @see https://apidocs.bookshare.org/reference/index.html#_address
#
class Api::Address < Api::Record::Base

  schema do
    attribute :address1,   String
    attribute :address2,   String
    attribute :city,       String
    attribute :country,    String
    attribute :postalCode, String
    attribute :state,      String
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
    full_address
  end

  # Display the address attributes in a single string.
  #
  # @param [String, nil] separator    Default: ' '.
  #
  # @return [String]
  #
  def full_address(separator: ' ')
    addr  = [address1, address2].reject(&:blank?).join(', ')
    place = [city, state].reject(&:blank?).join(', ')
    [addr, place, country, postalCode].reject(&:blank?).join(separator).squish
  end

end

__loading_end(__FILE__)
