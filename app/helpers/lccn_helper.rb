# app/helpers/lccn_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for handling LCCN (LoC Control Number) identifiers.
#
# @see http://www.loc.gov/marc/lccn_structure.html
#
module LccnHelper

  def self.included(base)
    __included(base, '[LccnHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Pre-2001 LCCNs have at least 13 characters; after that, 12 characters.
  #
  # @type [Integer]
  #
  LCCN_MIN_CHARS = 12

  # A pattern matching any of the expected LCCN prefixes.
  #
  # @type [Regexp]
  #
  LCCN_PREFIX = /^\s*LCCN:?\s*/i

  # A pattern matching the form of an LCCN identifier.
  #
  # @type [Regexp]
  #
  LCCN_IDENTIFIER = /^.{#{LCCN_MIN_CHARS},}$/

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given text appears to include an LCCN.
  #
  # @param [String] s
  #
  # Compare with:
  # @see #oclc?
  #
  # == Usage Notes
  # If *text* matches #LCCN_PREFIX then the method returns *true* even if the
  # actual number is invalid; the caller is expected to differentiate between
  # valid and invalid cases and handle each appropriately.
  #
  def contains_lccn?(s)
    s  = s.to_s.strip
    id = remove_lccn_prefix(s)
    (s != id) || (id =~ LCCN_IDENTIFIER)
  end

  # Indicate whether the string is a valid LCCN.
  #
  # @param [String] s
  #
  # Compare with:
  # @see #contains_oclc?
  #
  def lccn?(s)
    to_lccn(s, log: false).present?
  end

  # If the value is an LCCN return it in a normalized form or *nil* otherwise.
  #
  # This uses a heuristic which will accept 8 or more decimal digits as a valid
  # identifier.
  #
  # @param [String]  s
  # @param [Boolean] log
  #
  # @return [String]                  The OCN, zero-filled if necessary.
  # @return [nil]                     If *ocn* is not a valid OCLC identifier.
  #
  def to_lccn(s, log: true)
    lccn = s = remove_lccn_prefix(s)
    if (lccn.size >= LCCN_MIN_CHARS) || (lccn.delete('^0-9').size >= 8)
      lccn
    elsif log
      Log.info { "#{__method__}: #{s.inspect} is not a valid LCCN" }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Remove an optional "lccn:" prefix and return the base identifier.
  #
  # @param [String] s
  #
  # @return [String]
  #
  def remove_lccn_prefix(s)
    s.to_s.strip.sub(LCCN_PREFIX, '')
  end

end

__loading_end(__FILE__)
