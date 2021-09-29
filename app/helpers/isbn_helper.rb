# app/helpers/isbn_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for handling ISBN identifiers.
#
module IsbnHelper

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Number of digits in an ISBN-10.
  #
  # @type [Integer]
  #
  ISBN_10_DIGITS = 10

  # Number of digits in an ISBN-13.
  #
  # @type [Integer]
  #
  ISBN_13_DIGITS = 13

  # A valid ISBN has at least this many digits.
  #
  # @type [Integer]
  #
  ISBN_MIN_DIGITS = ISBN_10_DIGITS

  # A pattern matching any of the expected ISBN prefixes.
  #
  # @type [Regexp]
  #
  ISBN_PREFIX = /^ISBN[:\s]*/i

  # A pattern matching the form of an ISBN identifier.
  #
  # @type [Regexp]
  #
  ISBN_IDENTIFIER = /^(\d+[^\d]?)+(\d|X)$/

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given text appears to include an ISBN.
  #
  # @param [String] s
  #
  # == Usage Notes
  # If *text* matches #ISBN_PREFIX then the method returns *true* even if the
  # actual number is invalid; the caller is expected to differentiate between
  # valid and invalid cases and handle each appropriately.
  #
  def isbn_candidate?(s)
    text   = s.to_s.strip
    number = remove_isbn_prefix(text)
    return true unless number == text # Explicit "isbn:" prefix
    number.match?(ISBN_IDENTIFIER) && (number.count('0-9X') >= ISBN_MIN_DIGITS)
  end

  # Indicate whether the string is a valid ISBN.
  #
  # @param [String] s
  #
  def isbn?(s)
    isbn = remove_isbn_prefix(s)
    isbn_checksum(isbn).present? rescue false
  end

  # Indicate whether the string is a valid ISBN-13.
  #
  # @param [String] s
  #
  def isbn13?(s)
    isbn   = remove_isbn_prefix(s)
    check  = isbn.last.to_i
    digits = isbn.delete('^0-9')
    length = digits.size
    digits = digits[0..-2]
    # noinspection RubyMismatchedParameterType
    (length == ISBN_13_DIGITS) && (isbn_13_checksum(digits) == check)
  end

  # Indicate whether the string is a valid ISBN-10.
  #
  # @param [String] s
  #
  def isbn10?(s)
    isbn   = remove_isbn_prefix(s)
    check  = isbn.last
    digits = isbn.delete('^0-9')
    length = digits.size
    if check == 'X'
      length += 1
    else
      digits = digits[0..-2]
    end
    # noinspection RubyMismatchedParameterType
    (length == ISBN_10_DIGITS) && (isbn_10_checksum(digits) == check)
  end

  # If the value is an ISBN return it in a normalized form or *nil* otherwise.
  #
  # @param [String]  s
  # @param [Boolean] log
  #
  # @return [String]                  An ISBN-13 value.
  # @return [nil]                     If *s* was not a valid ISBN.
  #
  def to_isbn(s, log: true)
    to_isbn13(s, log: log)
  end

  # If the value is an ISBN-13; if it is an ISBN-10, convert it to the
  # equivalent ISBN-13; otherwise return *nil*.
  #
  # @param [String]  s
  # @param [Boolean] log
  #
  # @return [String]                  ISBN-13 version of *s*.
  # @return [nil]                     If *s* was not a valid ISBN-10.
  #
  def to_isbn13(s, log: true)
    isbn = remove_isbn_prefix(s).delete('^0-9X')
    if isbn13?(isbn)
      isbn
    elsif isbn.size != ISBN_10_DIGITS
      Log.info { "#{__method__}: #{s.inspect} is not a valid ISBN-10" } if log
    else
      digits = '978' + isbn[0..-2]
      check  = isbn_13_checksum(digits)
      "#{digits}#{check}"
    end
  end

  # If the value is an ISBN-10 return it; if it is an ISBN-13 that starts with
  # "978", convert it to the equivalent ISBN-10; otherwise return *nil*.
  #
  # @param [String]  s
  # @param [Boolean] log
  #
  # @return [String]                  ISBN-10 version of *s*.
  # @return [nil]                     If *s* was not a convertible ISBN-13.
  #
  def to_isbn10(s, log: true)
    isbn = remove_isbn_prefix(s).delete('^0-9X')
    if isbn10?(isbn)
      isbn
    elsif isbn.size != ISBN_13_DIGITS
      Log.info { "#{__method__}: #{s.inspect} is not a valid ISBN-13" } if log
    elsif isbn.delete_prefix!('978').blank?
      Log.info { "#{__method__}: cannot convert #{s.inspect}" } if log
    else
      digits = isbn[0..-2]
      # noinspection RubyMismatchedParameterType
      check  = isbn_10_checksum(digits)
      "#{digits}#{check}"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # isbn_checksum
  #
  # @param [String]  isbn
  # @param [Boolean] validate         If *false* only the valid result is
  #                                     returned; otherwise if *isbn* is a full
  #                                     ISBN (including the check digit), an
  #                                     exception is raised if the check digit
  #                                     is erroneous.
  #
  # @raise [RuntimeError]             If *isbn* contains a check digit but it
  #                                     is not valid.
  #
  # @return [Integer]                 Result of #isbn_13_checksum.
  # @return [String]                  Result of #isbn_10_checksum.
  # @return [nil]                     If *isbn* was not valid.
  #
  def isbn_checksum(isbn, validate: true)
    check  = isbn.last
    digits = isbn.delete('^0-9')
    # noinspection RubyMismatchedParameterType
    case digits.size

      when ISBN_13_DIGITS
        # Full ISBN-13.
        result = isbn_13_checksum(digits[0..-2])
        check  = check.to_i

      when ISBN_13_DIGITS - 1
        # ISBN-13 without check digit.
        result = isbn_13_checksum(digits)
        check  = nil

      when ISBN_10_DIGITS
        # Full ISBN-10.
        result = isbn_10_checksum(digits[0..-2])
        check  = check.to_s

      when ISBN_10_DIGITS - 1
        # ISBN-10 without check digit.
        result = isbn_10_checksum(digits)
        check  = nil unless check == 'X'

      else
        raise "#{isbn.inspect}: Invalid ISBN-10 or ISBN-13"

    end
    if check && (result != check)
      raise "#{isbn.inspect}: check digit should be #{result}" if validate
    else
      result
    end
  end

  # Calculate the ISBN-13 checksum for the supplied array of digits.
  #
  # @param [String, Array<String,Integer>] digits
  #
  # @return [Integer]                 A number in the range (0..9).
  #
  # @see https://www.isbn-international.org/content/isbn-users-manual
  #
  def isbn_13_checksum(digits)
    digits = digits.split('') if digits.is_a?(String)
    last   = ISBN_13_DIGITS - 2 # Last digit before check digit.
    total  =
      (0..last).sum do |index|
        weight = (index % 2).zero? ? 1 : 3
        digits[index].to_i * weight
      end
    remainder = total % 10
    ((10 - remainder) % 10)
  end

  # Calculate the ISBN-10 checksum for the supplied array of digits.
  #
  # @param [String, Array<String,Integer>] digits
  #
  # @return [String]                  Single-character decimal digit or 'X'.
  #
  # @see https://en.wikipedia.org/wiki/Check_digit#ISBN_10
  #
  def isbn_10_checksum(digits)
    digits = digits.split('') if digits.is_a?(String)
    last   = ISBN_10_DIGITS - 2 # Last digit before check digit.
    total  =
      (0..last).sum do |index|
        weight = index + 1
        digits[index].to_i * weight
      end
    remainder = total % 11
    (remainder == 10) ? 'X' : remainder.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Remove an optional "isbn:" prefix and return the base identifier.
  #
  # @param [String] s
  #
  # @return [String]
  #
  def remove_isbn_prefix(s)
    s.to_s.strip.sub(ISBN_PREFIX, '')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
