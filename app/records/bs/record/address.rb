# app/records/bs/record/address.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Address
#
# @attr [String] address1
# @attr [String] address2
# @attr [String] city
# @attr [String] country
# @attr [String] postalCode
# @attr [String] state
#
# @see https://apidocs.bookshare.org/reference/index.html#_address
#
class Bs::Record::Address < Bs::Api::Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one   :address1
    has_one   :address2
    has_one   :city
    has_one   :country
    has_one   :postalCode
    has_one   :state
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
  # @param [String] separator         Default: ' '.
  #
  # @return [String]
  #
  def full_address(separator: ' ')
    addr  = [address1, address2].compact_blank.join(', ')
    place = [city, state].compact_blank.join(', ')
    [addr, place, country, postalCode].compact_blank.join(separator).squish
  end

end

__loading_end(__FILE__)
