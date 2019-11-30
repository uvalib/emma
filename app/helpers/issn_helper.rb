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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A valid ISSN has at least this many digits.
  #
  # @type [Integer]
  #
  ISSN_MIN_DIGITS = 8

  # A valid ISSN has this number of digits ([0-9X]).
  #
  # @type [Integer]
  #
  ISSN_DIGITS = ISSN_MIN_DIGITS

  # A pattern matching any of the expected ISSN prefixes.
  #
  # @type [Regexp]
  #
  ISSN_PREFIX = /^\s*ISSN:?\s*/i

  # A pattern matching the form of an ISSN identifier.
  #
  # @type [Regexp]
  #
  ISSN_IDENTIFIER = /^(\d+[^\d]?)+(\d|X)$/i

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given text appears to include an ISSN.
  #
  # @param [String] text
  #
  # == Usage Notes
  # If *text* matches #ISSN_PREFIX then the method returns *true* even if the
  # actual number is invalid; the caller is expected to differentiate between
  # valid and invalid cases and handle each appropriately.
  #
  def contains_issn?(text)
    text = text.to_s.strip
    id   = remove_prefix(text)
    (text != id) ||
      ((id =~ ISSN_IDENTIFIER) && (id.delete('^0-9X').size >= ISSN_MIN_DIGITS))
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
    issn = remove_prefix(issn).delete('^0-9X')
    if issn.size != ISSN_DIGITS
      Log.info { "#{__method__}: #{issn.inspect} is not a valid ISSN" }
    else
      digits = issn[0..-2]
      digits + issn_checksum(digits)
    end
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
    digits = digits.split('') if digits.is_a?(String)
    last   = ISSN_DIGITS - 2 # Last digit before check digit.
    total  =
      (0..last).sum do |index|
        weight = ISSN_DIGITS - index
        digits[index].to_i * weight
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
    isbn.to_s.strip.sub(ISSN_PREFIX, '')
  end

end

__loading_end(__FILE__)
