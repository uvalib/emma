# app/helpers/isbn_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for handling ISBN identifiers.
#
module IsbnHelper

  def self.included(base)
    __included(base, '[IsbnHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given text appears to include an ISBN.
  #
  # @param [String] text
  #
  def contains_isbn?(text)
    text = remove_prefix(text)
    return false unless text =~ /^(\d+[^\d]?)+X?$/
    digits = text.delete('^0-9').size
    digits += 1 if text.end_with?('X')
    digits >= 10
  end

  # Indicate whether the string is a valid ISBN.
  #
  # @param [String] isbn
  #
  def isbn?(isbn)
    isbn = remove_prefix(isbn)
    [10, 13].include?(isbn.size) && isbn_checksum(isbn).present? rescue false
  end

  # Indicate whether the string is a valid ISBN-13.
  #
  # @param [String] isbn
  #
  def isbn13?(isbn)
    isbn   = remove_prefix(isbn)
    check  = isbn.last.to_i
    digits = isbn.delete('^0-9')
    (digits.size == 13) && (isbn_13_checksum(digits[0..-2]) == check)
  end

  # Indicate whether the string is a valid ISBN-10.
  #
  # @param [String] isbn
  #
  def isbn10?(isbn)
    isbn   = remove_prefix(isbn)
    check  = isbn.last
    digits = isbn.delete('^0-9')
    length = digits.size
    if check == 'X'
      length += 1
    else
      digits = digits[0..-2]
    end
    (length == 10) && (isbn_10_checksum(digits) == check)
  end

  # If the value is an ISBN return it in a normalized form or *nil* otherwise.
  #
  # @param [String] isbn
  #
  # @return [String]
  # @return [nil]
  #
  def to_isbn(isbn)
    to_isbn13(isbn)
  end

  # If the value is an ISBN-13; if it is an ISBN-10, convert it to the
  # equivalent ISBN-13; otherwise return *nil*.
  #
  # @param [String] isbn
  #
  # @return [String]
  # @return [nil]
  #
  def to_isbn13(isbn)
    isbn = remove_prefix(isbn).delete('^0-9X')
    return isbn if isbn13?(isbn)
    return unless isbn.size == 10
    isbn = '978' + isbn[0..-2]
    isbn + isbn_13_checksum(isbn)
  end

  # If the value is an ISBN-10 return it; if it is an ISBN-13 that starts with
  # "978", convert it to the equivalent ISBN-10; otherwise return *nil*.
  #
  # @param [String] isbn
  #
  # @return [String]
  # @return [nil]
  #
  def to_isbn10(isbn)
    isbn = remove_prefix(isbn).delete('^0-9X')
    return isbn if isbn10?(isbn)
    return unless isbn.size == 13
    return unless isbn.delete_prefix!('978')
    isbn = isbn[0..-2]
    isbn + isbn_10_checksum(isbn)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # isbn_checksum
  #
  # @param [String]  isbn
  # @param [Boolean] validate         If *false* only the valid result is
  #                                     returned; otherwise if *s* is a full
  #                                     ISBN (including the check digit), an
  #                                     exception is raised if the check digit
  #                                     is erroneous.
  #
  # @raise [StandardError]            If *s* contains a check digit but it is
  #                                     not valid.
  #
  # @return [Integer]                 Result of #isbn_13_checksum.
  # @return [String]                  Result of #isbn_10_checksum.
  #
  def isbn_checksum(isbn, validate: true)
    isbn   = remove_prefix(isbn)
    check  = isbn.last
    digits = isbn.delete('^0-9')
    case digits.size
      when 13
        result = isbn_13_checksum(digits[0..-2])
        check  = check.to_i
      when 12
        result = isbn_13_checksum(digits)
        check  = nil
      when 10
        result = isbn_10_checksum(digits[0..-2])
        check  = check.to_s
      when 9
        result = isbn_10_checksum(digits)
        check  = nil unless check == 'X'
      else
        raise "#{isbn.inspect}: Invalid ISBN-10 or ISBN-13"
    end
    if validate && check && (result != check)
      raise "#{isbn.inspect}: check digit should be #{result}"
    end
    result
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
    total = 0
    digits = digits.split('') if digits.is_a?(String)
    digits.each_with_index do |digit, index|
      break if index == 12 # Ignore the check digit if present.
      weight = (index % 2).zero? ? 1 : 3
      total += digit.to_i * weight
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
    total = 0
    digits = digits.split('') if digits.is_a?(String)
    digits.each_with_index do |digit, index|
      break if index == 9 # Ignore the check digit if present.
      weight = index + 1
      total += digit.to_i * weight
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
  # @param [String] isbn
  #
  # @return [String]
  #
  def remove_prefix(isbn)
    isbn.to_s.strip.upcase.sub(/^ISBN:?\s*/, '')
  end

end

__loading_end(__FILE__)
