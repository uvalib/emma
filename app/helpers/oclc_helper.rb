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
  OCLC_PREFIX = /^\s*(#{OCLC_FORMAT.keys.join('|')}):?\s*/i

  # A pattern matching the form of an ISSN identifier.
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
  # @param [String] text
  #
  # Compare with:
  # @see #oclc?
  #
  # == Usage Notes
  # If *text* matches #OCLC_PREFIX then the method returns *true* even if the
  # actual number is invalid; the caller is expected to differentiate between
  # valid and invalid cases and handle each appropriately.
  #
  def contains_oclc?(text)
    text = text.to_s.strip
    id   = remove_prefix(text)
    (text != id) || (id =~ OCLC_IDENTIFIER)
  end

  alias_method :contains_ocn?, :contains_oclc?

  # Indicate whether the string is a valid OCN.
  #
  # @param [String] ocn
  #
  # Compare with:
  # @see #contains_oclc?
  #
  def oclc?(ocn)
    to_oclc(ocn).present?
  end

  alias_method :ocn?, :oclc?

  # If the value is an OCN return it in a normalized form or *nil* otherwise.
  #
  # If the string has a prefix then the number of included digits must match
  # the number specified by the prefix.  If the string is only digits then it
  # will be zero-filled on the left to make a valid OCN.
  #
  # @param [String] ocn
  #
  # @return [String]                  The OCN, zero-filled if necessary.
  # @return [nil]                     If *ocn* is not a valid OCLC identifier.
  #
  def to_oclc(ocn)
    ocn       = ocn.to_s.strip
    entry     = OCLC_FORMAT.select { |prefix, _| ocn =~ /^#{prefix}/i }
    min, max  = entry.values.first || Array.wrap(OCLC_MIN_DIGITS)
    digits    = remove_prefix(ocn)
    zero_fill = (min.to_i - digits.size unless ocn == digits)
    digits.insert(0, ('0' * zero_fill)) if zero_fill.to_i > 0
    if digits =~ /^\d{#{min},#{max}}$/
      digits
    else
      Log.info { "#{__method__}: #{ocn.inspect} is not a valid OCN" }
    end
  end

  alias_method :to_ocn, :to_oclc

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Remove an optional "oclc:" prefix and return the base identifier.
  #
  # @param [String] ocn
  #
  # @return [String]
  #
  def remove_prefix(ocn)
    ocn.to_s.strip.sub(OCLC_PREFIX, '')
  end

end

__loading_end(__FILE__)
