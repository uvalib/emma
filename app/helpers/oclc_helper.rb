# app/helpers/oclc_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for handling OCN (OCLC Control Number) identifiers.
#
# @see https://www.oclc.org/developer/news/2012/oclc-control-number-expansion-in-2013.en.html
#
module OclcHelper

  def self.included(base)
    __included(base, '[OclcHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A valid OCN has at least this many digits.
  #
  # @type [Integer]
  #
  OCLC_MIN_DIGITS = 8

  # The minimum/maximum number of digits associated with each expected OCN
  # prefix.
  #
  # @type [Hash{Symbol=>Array<Integer,nil>}]
  #
  OCLC_FORMAT = {
    ocn:       [8, 8],                # E.g. "ocn12345678"
    ocm:       [9, 9],                # E.g. "ocm123456789"
    on:        10,                    # E.g. "on1234567890"
    OCLC:      OCLC_MIN_DIGITS,       # E.g. "OCLC:12345678"
    OCoLC:     OCLC_MIN_DIGITS,       # E.g. "OCoLC:12345678"
    '(OCoLC)': OCLC_MIN_DIGITS        # E.g. "(OCoLC)12345678"
  }.transform_values { |minmax| Array.wrap(minmax) }.deep_freeze

  # A pattern matching any of the expected OCN prefixes.
  #
  # @type [Regexp]
  #
  OCLC_PREFIX = /^\s*(#{OCLC_FORMAT.keys.join('|')})[:\s]*/i

  # A pattern matching the form of an OCN identifier.
  #
  # @type [Regexp]
  #
  OCLC_IDENTIFIER = /^\d{#{OCLC_MIN_DIGITS},}$/

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given text appears to include an OCN.
  #
  # @param [String] s
  #
  # Compare with:
  # @see #oclc?
  #
  # == Usage Notes
  # If *text* matches #OCLC_PREFIX then the method returns *true* even if the
  # actual number is invalid; the caller is expected to differentiate between
  # valid and invalid cases and handle each appropriately.  The one exception
  # is if the prefix is "on" -- here a the remainder must be a valid OCLC
  # number (otherwise words like "one" are interpreted as "oclc:e").
  #
  def contains_oclc?(s)
    s  = s.to_s.strip
    id = remove_oclc_prefix(s)
    !s.downcase.start_with?('on') && (s != id) || id.match?(OCLC_IDENTIFIER)
  end

  alias_method :contains_ocn?, :contains_oclc?

  # Indicate whether the string is a valid OCN.
  #
  # @param [String] s
  #
  # Compare with:
  # @see #contains_oclc?
  #
  def oclc?(s)
    to_oclc(s, log: false).present?
  end

  alias_method :ocn?, :oclc?

  # If the value is an OCN return it in a normalized form or *nil* otherwise.
  #
  # If the string has a prefix then the number of included digits must match
  # the number specified by the prefix.  If the string is only digits then it
  # will be zero-filled on the left to make a valid OCN.
  #
  # @param [String]  s
  # @param [Boolean] log
  #
  # @return [String]                  The OCN, zero-filled if necessary.
  # @return [nil]                     If *ocn* is not a valid OCLC identifier.
  #
  def to_oclc(s, log: true)
    s         = s.to_s.strip
    entry     = OCLC_FORMAT.select { |prefix, _| s =~ /^#{prefix}/i }
    min, max  = entry.values.first || Array.wrap(OCLC_MIN_DIGITS)
    s         = remove_oclc_prefix(s)
    digits    = s.delete('^0-9')
    zero_fill = min.to_i - digits.size
    digits.prepend('0' * zero_fill) if zero_fill > 0
    if digits =~ /^\d{#{min},#{max}}$/
      digits
    elsif log
      Log.info { "#{__method__}: #{s.inspect} is not a valid OCN" }
    end
  end

  alias_method :to_ocn, :to_oclc

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Remove an optional "oclc:" prefix and return the base identifier.
  #
  # @param [String] s
  #
  # @return [String]
  #
  def remove_oclc_prefix(s)
    s.to_s.strip.sub(OCLC_PREFIX, '')
  end

end

__loading_end(__FILE__)
