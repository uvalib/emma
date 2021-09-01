# app/helpers/issn_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for handling ISSN identifiers.
#
module IssnHelper

  # @private
  def self.included(base)
    __included(base, 'IssnHelper')
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
  ISSN_PREFIX = /^\s*ISSN[:\s]*/i

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
  # @param [String] s
  #
  # == Usage Notes
  # If *text* matches #ISSN_PREFIX then the method returns *true* even if the
  # actual number is invalid; the caller is expected to differentiate between
  # valid and invalid cases and handle each appropriately.
  #
  def contains_issn?(s)
    s  = s.to_s.strip
    id = remove_issn_prefix(s)
    (s != id) || # Explicit "issn:" prefix
      ((id =~ ISSN_IDENTIFIER) && (id.delete('^0-9X').size >= ISSN_MIN_DIGITS))
  end

  # Indicate whether the string is a valid ISSN.
  #
  # @param [String] s
  #
  def issn?(s)
    issn   = remove_issn_prefix(s)
    check  = issn.last
    digits = issn.delete('^0-9')
    length = digits.size
    if check == 'X'
      length += 1
    else
      digits = digits[0..-2]
    end
    # noinspection RubyMismatchedParameterType
    (length == ISSN_DIGITS) && (issn_checksum(digits) == check)
  end

  # If the value is an ISSN return it in a normalized form or *nil* otherwise.
  #
  # @param [String]  s
  # @param [Boolean] log
  # @param [Boolean] validate         If *true*, raise an exception if the
  #                                     checksum provided in *s* is invalid.
  #
  # @raise [RuntimeError]             If *issn* contains a check digit but it
  #                                     is not valid.
  #
  # @return [String]                  An ISSN value.
  # @return [nil]                     If *s* was not a valid ISSN.
  #
  def to_issn(s, log: true, validate: false)
    issn   = remove_issn_prefix(s).delete('^0-9X')
    digits = check = nil
    if issn.size == (ISSN_DIGITS - 1) # ISSN without check digit.
      digits = issn
    elsif issn.size == ISSN_DIGITS
      digits = issn[0..-2]
      check  = issn.last.to_i
    elsif log
      Log.info { "#{__method__}: #{s.inspect} is not a valid ISSN" }
    end
    if digits
      result = issn_checksum(digits)
      if validate && check && (result != check)
        raise "#{issn.inspect}: check digit should be #{result}"
      end
      "#{digits}#{result}"
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

  # Remove an optional "issn:" prefix and return the base identifier.
  #
  # @param [String] s
  #
  # @return [String]
  #
  def remove_issn_prefix(s)
    s.to_s.strip.sub(ISSN_PREFIX, '')
  end

end

__loading_end(__FILE__)
