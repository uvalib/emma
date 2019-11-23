# app/helpers/issn_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for handling ISSN identifiers.
#
module IssnHelper

  def self.included(base)
    __included(base, '[IssnHelper]')
  end

  ISSN_DIGITS = 8

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given text appears to include an ISSN.
  #
  # @param [String] text
  #
  def contains_issn?(text)
    text = remove_prefix(text)
    return false unless text =~ /^(\d+[^\d]?)+X?$/
    digits = text.delete('^0-9').size
    digits += 1 if text.end_with?('X')
    digits == ISSN_DIGITS
  end

  # Indicate whether the string is a valid ISSN.
  #
  # @param [String] issn
  #
  def issn?(issn)
    issn   = remove_prefix(issn)
    check  = issn.last
    digits = issn.delete('^0-9')
    length = digits.size
    if check == 'X'
      length += 1
    else
      digits = digits[0..-2]
    end
    (length == ISSN_DIGITS) && (issn_checksum(digits) == check)
  end

  # If the value is an ISSN return it in a normalized form or *nil* otherwise.
  #
  # @param [String] issn
  #
  # @return [String]
  # @return [nil]
  #
  def to_issn(issn)
    issn = remove_prefix(issn)
    digits = issn.delete('^0-9X')
    return unless digits.size == ISSN_DIGITS
    digits = digits[0..-2]
    digits + issn_checksum(digits)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Calculate the ISSN checksum for the supplied array of digits.
  #
  # @param [String, Array<String,Integer>] digits
  #
  # @return [String]                  Single-character decimal digit or 'X'.
  #
  # @see https://www.issn.org/understanding-the-issn/assignment-rules/issn-manual/#2-1-construction-of-issn
  #
  def issn_checksum(digits)
    total = 0
    digits = digits.split('') if digits.is_a?(String)
    digits.each_with_index do |digit, index|
      break if index == (ISSN_DIGITS - 1) # Ignore the check digit if present.
      weight = (ISSN_DIGITS - index)
      total += digit.to_i * weight
    end
    remainder = 11 - (total % 11)
    (remainder == 10) ? 'X' : remainder.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Remove an optional "isbn:" prefix and return the base identifier.
  #
  # @param [String] isbn
  #
  # @return [String]
  #
  def remove_prefix(isbn)
    isbn.to_s.strip.upcase.sub(/^ISSN:?\s*/, '')
  end

end

__loading_end(__FILE__)
