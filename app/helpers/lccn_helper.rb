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

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Pre-2001 LCCNs have at least 13 characters; after that, 12 characters.
  #
  # The first characters (three prior to 2001, otherwise two) are alphabetic,
  # but they may also be given as spaces.  It's not unlikely that they would be
  # omitted from non-MARC metadata renderings.
  #
  # Pre-2001, the final character (supplement number) may also be given as a
  # space.
  #
  # @type [Range]
  #
  LCCN_DIGITS = (8..10).freeze

  # A pattern matching any of the expected LCCN prefixes.
  #
  # @type [Regexp]
  #
  LCCN_PREFIX = /^\s*LCCN(\s*:)?/i

  # A pattern matching the form of an LCCN identifier.
  #
  # @type [Regexp]
  #
  LCCN_IDENTIFIER = /^
    (
      ([ _#a-z]{3})?\d{8}[ _#]? |
      ([ _#a-z]{3})?\d{9}       |
      ([ _#a-z]{2})?\d{10}
    )(\/.*)?$
  /ix

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the given text appears to include an LCCN.
  #
  # @param [String] s
  #
  # == Usage Notes
  # If *text* matches #LCCN_PREFIX then the method returns *true* even if the
  # actual number is invalid; the caller is expected to differentiate between
  # valid and invalid cases and handle each appropriately.
  #
  def lccn_candidate?(s)
    text   = s.to_s.strip
    number = remove_lccn_prefix(text)
    return true unless number == text # Explicit "lccn:" prefix
    number.match?(LCCN_IDENTIFIER)
  end

  # Indicate whether the string is a valid LCCN.
  #
  # @param [String] s
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
  # @return [nil]                     If *s* is not a valid OCLC identifier.
  #
  def to_lccn(s, log: true)
    lccn   = remove_lccn_prefix(s)
    digits = lccn.sub(%r{/.*$}, '').delete('^0-9')
    if LCCN_DIGITS.include?(digits.size)
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
