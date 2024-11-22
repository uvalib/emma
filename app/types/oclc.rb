# app/types/oclc.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# OCN (OCLC Control Number) identifier.
#
# @see https://www.oclc.org/developer/news/2012/oclc-control-number-expansion-in-2013.en.html
#
class Oclc < PublicationIdentifier

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

    # The minimum/maximum number of digits associated with each expected OCN
    # prefix.
    #
    # @type [Hash{Symbol=>Array<Integer,nil>}]
    #
    OCLC_FORMAT = {
      ocn:        [8,  8],    # E.g. "ocn12345678"
      ocm:        [9,  9],    # E.g. "ocm123456789"
      on:         [10, nil],  # E.g. "on1234567890"
      OCLC:       [8,  nil],  # E.g. "OCLC:12345678"
      OCoLC:      [8,  nil],  # E.g. "OCoLC:12345678"
      '(OCoLC)':  [8,  nil],  # E.g. "(OCoLC)12345678"
    }.deep_freeze

    # A valid OCN has a number of digits in this range.
    #
    # @type [Range]
    #
    OCLC_DIGITS =
      OCLC_FORMAT.values.flatten.compact.then { _1.min .. _1.max }.freeze

    # If a value has a number of digits within this range it could be either a
    # valid OCLC or intended as an OCLC but with too few or one too many
    # digits.
    #
    # @type [Range]
    #
    # === Implementation Notes
    # The minimum is a heuristic to account for OCLC numbers that were not
    # left-zero-filled to give the number 8 digits.
    #
    CANDIDATE_RANGE = (3..(OCLC_DIGITS.max+1)).freeze

    # A pattern matching any of the expected OCN prefixes.
    #
    # @type [Regexp]
    #
    OCLC_PREFIX =
      /^\s*(#{OCLC_FORMAT.keys.join('|').gsub(/[()]/, '\\\\\0')}):?\s*/i.freeze

    # A pattern matching the form of an OCN identifier.
    #
    # @type [Regexp]
    #
    OCLC_IDENTIFIER = /^(
      \d{#{OCLC_DIGITS.minmax.join(',')}} |                  # Well-formed.
      [1-9]\d{#{CANDIDATE_RANGE.min-1},#{OCLC_DIGITS.min-1}} # Not zero-filled.
    )$/x.freeze

    # A pattern matching the form of a (possibly invalid) OCN identifier.
    #
    # @type [Regexp]
    #
    OCLC_CANDIDATE = /^\d{#{CANDIDATE_RANGE.minmax.join(',')}}$/.freeze

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether `*v*` would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      oclc?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      to_oclc(v, log: false) || remove_prefix(v).delete('^0-9')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the given value appears to include an OCN.
    #
    # @param [any, nil] v
    #
    # === Usage Notes
    # If *v* matches #OCLC_PREFIX then the method returns *true* even if the
    # actual number is invalid; the caller is expected to differentiate between
    # valid and invalid cases and handle each appropriately.  The one exception
    # is if the prefix is "on" -- here the remainder must be a valid OCLC
    # number (otherwise words like "one" would be interpreted as "oclc:e").
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(OCLC_PREFIX, '')
      v.match?(OCLC_CANDIDATE)
    end

    # Extract the base identifier of a possible OCN.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(OCLC_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def remove_prefix(v)
      v.to_s.sub(OCLC_PREFIX, '')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the value is a valid OCN.
    #
    # @param [any, nil] v
    #
    def oclc?(v)
      to_oclc(v, log: false).present?
    end

    # If the value is an OCN return it in a normalized form or *nil* otherwise.
    #
    # If the string has a prefix then the number of included digits must match
    # the number specified by the prefix.  If the string is only digits then it
    # will be zero-filled on the left to make a valid OCN.
    #
    # @param [any, nil] v
    # @param [Boolean]  log
    #
    # @return [String, nil]
    #
    def to_oclc(v, log: true, **)
      v        = v.to_s.strip
      prefix   = v.match(OCLC_PREFIX) && $1
      min, max = [OCLC_DIGITS.min]
      OCLC_FORMAT.find do |p, minmax|
        min, max = minmax if p.to_s.casecmp?(prefix)
      end
      if (digits = identifier(v)&.delete('^0-9')&.presence)
        zero_fill = min.to_i - digits.size
        digits.prepend('0' * zero_fill) if zero_fill > 0
        return digits if digits.match?(/^\d{#{min},#{max}}$/)
      end
      Log.info { "#{__method__}: #{v.inspect} is not a valid OCN" } if log
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
