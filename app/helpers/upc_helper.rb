# app/helpers/upc_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for handling UPC (Universal Pricing Code) identifiers.
#
module UpcHelper

  # @private
  def self.included(base)
    __included(base, 'UpcHelper')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A valid UPC has at least this many digits.
  #
  # Some forms have supplemental digits in addition to the base UPC number.
  #
  # @type [Integer]
  #
  UPC_DIGITS = 12

  # A pattern matching any of the expected UPC prefixes.
  #
  # @type [Regexp]
  #
  UPC_PREFIX = /^\s*UPC[:\s]*/i

  # A pattern matching the form of an UPC identifier.
  #
  # @type [Regexp]
  #
  UPC_IDENTIFIER = /^\d{#{UPC_DIGITS},}$/

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given text appears to include an UPC.
  #
  # @param [String] s
  #
  # == Usage Notes
  # If *text* matches #UPC_PREFIX then the method returns *true* even if the
  # actual number is invalid; the caller is expected to differentiate between
  # valid and invalid cases and handle each appropriately.
  #
  def contains_upc?(s)
    s  = s.to_s.strip
    id = remove_upc_prefix(s)
    (s != id) ||
      ((id =~ UPC_IDENTIFIER) && (id.delete('^0-9').size >= UPC_DIGITS))
  end

  # Indicate whether the string is a valid UPC.
  #
  # @param [String] s
  #
  def upc?(s)
    upc   = remove_upc_prefix(s)
    digits = upc.delete('^0-9')
    length = digits.size
    last   = UPC_DIGITS - 1 # The check digit.
    check  = digits[last]
    digits = digits[0..(last-1)]
    # noinspection RubyYardParamTypeMatch
    (length >= UPC_DIGITS) && (upc_checksum(digits) == check)
  end

  # If the value is an UPC return it in a normalized form or *nil* otherwise.
  #
  # @param [String]  s
  # @param [Boolean] log
  # @param [Boolean] validate         If *true*, raise an exception if the
  #                                     checksum provided in *s* is invalid.
  #
  # @raise [StandardError]            If *s* contains a check digit but it is
  #                                     not valid.
  #
  # @return [String]                  A UPC value.
  # @return [nil]                     If *s* was not a valid UPC.
  #
  def to_upc(s, log: true, validate: false)
    upc    = remove_upc_prefix(s).delete('^0-9')
    digits = check = added = nil
    if upc.size == (UPC_DIGITS - 1) # UPC without check digit.
      digits = upc
    elsif upc.size >= UPC_DIGITS
      last   = UPC_DIGITS - 1 # Position of the check digit.
      digits = upc[0..(last-1)]
      check  = upc[last].to_i
      added  = upc[(last+1)..-1] if upc.size > UPC_DIGITS
    elsif log
      Log.info { "#{__method__}: #{s.inspect} is not a valid UPC" }
    end
    if digits
      result = upc_checksum(digits)
      if validate && check && (result != check)
        raise "#{upc.inspect}: check digit should be #{result}"
      end
      "#{digits}#{result}#{added}"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Calculate the UPC checksum for the supplied array of digits.
  #
  # @param [String, Array<String,Integer>] digits
  #
  # @return [Integer]                 A number in the range (0..9).
  #
  def upc_checksum(digits)
    digits = digits.split('') if digits.is_a?(String)
    check  = UPC_DIGITS - 1 # Position of the check digit.
    total  =
      (0..(check-1)).sum do |index|
        weight = (index % 2).zero? ? 3 : 1
        digits[index].to_i * weight
      end
    remainder = total % 10
    ((10 - remainder) % 10)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Remove an optional "upc:" prefix and return the base identifier.
  #
  # @param [String] s
  #
  # @return [String]
  #
  def remove_upc_prefix(s)
    s.to_s.sub(UPC_PREFIX, '')
  end

end

__loading_end(__FILE__)
