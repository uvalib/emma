# app/types/isbn.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ISBN identifier.
#
class Isbn < PublicationIdentifier

  PREFIX = name.underscore
  TYPE   = PREFIX.to_sym

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include PublicationIdentifier::Methods

    # =========================================================================
    # :section:
    # =========================================================================

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

    # If a value has a number of digits within this range it could be either a
    # valid ISBN or intended as an ISBN but with one too few or one too many
    # digits.
    #
    # @type [Range]
    #
    CANDIDATE_RANGE = ((ISBN_10_DIGITS-1)..(ISBN_13_DIGITS+1)).freeze

    # A pattern matching any of the expected ISBN prefixes.
    #
    # @type [Regexp]
    #
    ISBN_PREFIX = /^\s*ISBN(:\s*|\s+)/i.freeze

    # Pattern fragment for a valid separator between groups of ISBN digits.
    #
    # @type [String]
    #
    SEPARATOR = '[\x20[:punct:]]'

    # A pattern matching the form of an ISBN identifier.
    #
    # @type [Regexp]
    #
    ISBN_IDENTIFIER = /^
      (\d#{SEPARATOR}*){#{ISBN_10_DIGITS-1}}([\dX]#{SEPARATOR}*) |
      (\d#{SEPARATOR}*){#{ISBN_13_DIGITS}}
    $/ix.freeze

    # A pattern matching the form of a (possibly invalid) ISBN identifier.
    #
    # @type [Regexp]
    #
    ISBN_CANDIDATE = /^
      (\d#{SEPARATOR}*){#{CANDIDATE_RANGE.min-1},#{CANDIDATE_RANGE.max-1}}
      [\dX]#{SEPARATOR}*
    $/ix.freeze

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      isbn?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      remove_prefix(v).remove!(/#{SEPARATOR}/)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the given value appears to include an ISBN.
    #
    # @param [any, nil] v
    #
    # === Usage Notes
    # If *v* matches #ISBN_PREFIX then the method returns *true* even if the
    # actual number is invalid; the caller is expected to differentiate between
    # valid and invalid cases and handle each appropriately.
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(ISBN_PREFIX, '').present? || v.match?(ISBN_CANDIDATE)
    end

    # Extract the base identifier of a possible ISBN.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(ISBN_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def remove_prefix(v)
      v.to_s.sub(ISBN_PREFIX, '')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the value is a valid ISBN.
    #
    # @param [any, nil] v
    #
    def isbn?(v)
      isbn = identifier(v) or return false
      checksum(isbn) == isbn.last
    end

    # Indicate whether the string is a valid ISBN-13.
    #
    # @param [any, nil] v
    #
    def isbn13?(v)
      isbn   = identifier(v) or return false
      check  = isbn.last
      digits = isbn.delete('^0-9')
      length = digits.size
      digits = digits[0...-1]
      # noinspection RubyMismatchedArgumentType
      (length == ISBN_13_DIGITS) && (isbn13_checksum(digits) == check)
    end

    # Indicate whether the value is a valid ISBN-10.
    #
    # @param [any, nil] v
    #
    def isbn10?(v)
      isbn   = identifier(v) or return false
      check  = isbn.last.upcase
      digits = isbn.delete('^0-9')
      length = digits.size
      if check == 'X'
        length += 1
      else
        digits = digits[0...-1]
      end
      # noinspection RubyMismatchedArgumentType
      (length == ISBN_10_DIGITS) && (isbn10_checksum(digits) == check)
    end

    # If the value is an ISBN return it in a normalized form.
    #
    # @param [any, nil] v
    # @param [Hash]     opt             Passed to #to_isbn13.
    #
    # @return [String, nil]
    #
    def to_isbn(v, **opt)
      to_isbn13(v, **opt)
    end

    # If the value is an ISBN-13; if it is an ISBN-10, convert it to the
    # equivalent ISBN-13; otherwise return *nil*.
    #
    # @param [any, nil] v
    # @param [Boolean]  log
    #
    # @return [String, nil]
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def to_isbn13(v, log: true, **)
      digits = identifier(v)&.delete('^0-9xX')
      isbn10 = (digits&.size == ISBN_10_DIGITS)
      check  = digits&.last&.upcase
      digits = digits&.slice(0...-1)
      valid  = digits && (check == checksum(digits))
      if isbn10 && valid
        return +'978' << digits << isbn13_checksum(digits)
      elsif isbn10
        log &&= "#{v.inspect} is not a valid ISBN-10"
      elsif valid
        return digits << check
      else
        log &&= "#{v.inspect} is not a valid ISBN-13"
      end
      Log.info { "#{__method__}: #{log}" } if log
    end

    # If the value is an ISBN-10 return it; if it is an ISBN-13 that starts
    # with "978", convert it to the equivalent ISBN-10; otherwise return *nil*.
    #
    # @param [any, nil] v
    # @param [Boolean]  log
    #
    # @return [String, nil]
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def to_isbn10(v, log: true, **)
      digits = identifier(v)&.delete('^0-9xX')
      isbn13 = (digits&.size == ISBN_13_DIGITS)
      check  = digits&.last&.upcase
      digits = digits&.slice(0...-1)
      valid  = digits && (check == checksum(digits))
      if isbn13 && valid && digits&.delete_prefix!('978')
        return digits << isbn10_checksum(digits)
      elsif isbn13 && valid
        log &&= "cannot convert #{v.inspect}"
      elsif isbn13
        log &&= "#{v.inspect} is not a valid ISBN-13"
      elsif valid
        return digits << check
      else
        log &&= "#{v.inspect} is not a valid ISBN-10"
      end
      Log.info { "#{__method__}: #{log}" } if log
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Generic ISBN checksum.
    #
    # @param [String]  isbn
    # @param [Boolean] validate         If *true* an exception is raised if the
    #                                     check digit is erroneous.
    #
    # @raise [RuntimeError]             If *isbn* contains a check digit but it
    #                                     is not valid.
    #
    # @return [String, nil]
    #
    def checksum(isbn, validate: false, **)
      final  = isbn.last.upcase
      digits = isbn.delete('^0-9xX')
      # noinspection RubyMismatchedArgumentType
      case digits.size
        when ISBN_13_DIGITS                 # Full ISBN-13.
          digits = digits[0...-1]
          check  = isbn13_checksum(digits)
          fail   = (check != final)
        when ISBN_13_DIGITS - 1             # ISBN-13 without check digit.
          check  = isbn13_checksum(digits)
          fail   = false
        when ISBN_10_DIGITS                 # Full ISBN-10.
          digits = digits[0...-1]
          check  = isbn10_checksum(digits)
          fail   = (check != final)
        when ISBN_10_DIGITS - 1             # ISBN-10 without check digit.
          check  = isbn10_checksum(digits)
          fail   = false
        else
          check  = nil
          fail   = true
      end
      if validate
        raise "#{isbn.inspect}: Invalid ISBN-10 or ISBN-13"     if check.nil?
        raise "#{isbn.inspect}: check digit should be #{check}" if fail
      end
      check
    end

    # Calculate the ISBN-13 checksum for the supplied array of digits.
    #
    # @param [String, Array<String,Integer>] digits
    #
    # @return [String]                  Single-character decimal digit.
    #
    # @see https://www.isbn-international.org/content/isbn-users-manual
    #
    def isbn13_checksum(digits)
      digits = digits.split('') if digits.is_a?(String)
      last   = ISBN_13_DIGITS - 2 # Last digit before check digit.
      total  =
        (0..last).sum do |index|
          weight = (index % 2).zero? ? 1 : 3
          digits[index].to_i * weight
        end
      remainder = total % 10
      ((10 - remainder) % 10).to_s
    end

    # Calculate the ISBN-10 checksum for the supplied array of digits.
    #
    # @param [String, Array<String,Integer>] digits
    #
    # @return [String]                  Single-character decimal digit or 'X'.
    #
    # @see https://en.wikipedia.org/wiki/Check_digit#ISBN_10
    #
    def isbn10_checksum(digits)
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

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include Methods

  # ===========================================================================
  # :section: PublicationIdentifier::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid.
  #
  # @param [any, nil] v               Default: #value.
  #
  def valid?(v = nil)
    v ||= value
    super
  end

  # Indicate whether the instance is a valid ISBN-13.
  #
  # @param [any, nil] v               Default: #value.
  #
  def isbn13?(v = nil)
    v ||= value
    super
  end

  # Indicate whether the instance is a valid ISBN-10.
  #
  # @param [any, nil] v               Default: #value.
  #
  def isbn10?(v = nil)
    v ||= value
    super
  end

end

__loading_end(__FILE__)
