# app/types/issn.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ISSN identifier.
#
class Issn < PublicationIdentifier

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

    # A valid ISSN has this number of digits ([0-9X]).
    #
    # @type [Integer]
    #
    ISSN_DIGITS = 8

    # If a value has a number of digits within this range it could be either a
    # valid ISSN or intended as an ISSN but with one too few or one too many
    # digits.
    #
    # @type [Range]
    #
    CANDIDATE_RANGE = ((ISSN_DIGITS-1)..(ISSN_DIGITS+1)).freeze

    # A pattern matching any of the expected ISSN prefixes.
    #
    # @type [Regexp]
    #
    ISSN_PREFIX = /^\s*ISSN(:\s*|\s+)/i.freeze

    # Pattern fragment for a valid separator between groups of ISSN digits.
    #
    # @type [String]
    #
    SEPARATOR = '[\x20[:punct:]]'

    # A pattern matching the form of an ISSN identifier.
    #
    # @type [Regexp]
    #
    ISSN_IDENTIFIER =
      /^(\d#{SEPARATOR}*){#{ISSN_DIGITS-1}}([\dX]#{SEPARATOR}*)$/i.freeze

    # A pattern matching the form of a (possibly invalid) ISSN identifier.
    #
    # @type [Regexp]
    #
    ISSN_CANDIDATE = /^
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
      issn?(v)
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

    # Indicate whether the given value appears to include an ISSN.
    #
    # @param [any, nil] v
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(ISSN_PREFIX, '').present? || v.match?(ISSN_CANDIDATE)
    end

    # Extract the base identifier of a possible ISSN.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(ISSN_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def remove_prefix(v)
      v.to_s.sub(ISSN_PREFIX, '')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the value is a valid ISSN.
    #
    # @param [any, nil] v
    #
    def issn?(v)
      to_issn(v, log: false, validate: true).present?
    end

    # If the value is an ISSN return it in a normalized form or *nil* otherwise
    #
    # @param [any, nil] v
    # @param [Boolean]  log
    # @param [Boolean]  validate      If *true*, return *nil* if the checksum
    #                                   provided in *v* is invalid.
    #
    # @return [String, nil]
    #
    def to_issn(v, log: true, validate: false, **)
      digits = identifier(v)&.delete('^0-9xX')
      if digits&.size == ISSN_DIGITS
        final  = digits.last.upcase
        digits = digits[0...-1]
        # noinspection RubyMismatchedArgumentType
        check  = checksum(digits)
        if !validate || (check == final)
          digits << check
        elsif log
          err = "check digit should be #{check}"
          Log.info { "#{__method__}: #{v.inspect}: #{err}" }
        end
      elsif log
        Log.info { "#{__method__}: #{v.inspect} is not a valid ISSN" }
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Calculate the ISSN checksum for the supplied array of digits.
    #
    # @param [String, Array<String,Integer>] digits
    #
    # @return [String]                  Single-character decimal digit or 'X'.
    #
    # @see https://www.issn.org/understanding-the-issn/assignment-rules/issn-manual/#2-1-construction-of-issn
    #
    def checksum(digits)
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

end

__loading_end(__FILE__)
