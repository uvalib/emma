# app/types/lccn.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LCCN (LoC Control Number) identifier.
#
# @see http://www.loc.gov/marc/lccn_structure.html
#
class Lccn < PublicationIdentifier

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

    # Pre-2001 LCCNs have at least 13 characters; after that, 12 characters.
    #
    # The first characters (three prior to 2001, otherwise two) are alphabetic,
    # but they may also be given as spaces.  It's not unlikely that they would
    # be omitted from non-MARC metadata renderings.
    #
    # Pre-2001, the final character (supplement number) may also be given as a
    # space.
    #
    # @type [Range]
    #
    LCCN_DIGITS = (8..10).freeze

    # If a value has a number of digits within this range it could be either a
    # valid LCCN or intended as an LCCN but with one too few or one too many
    # digits.
    #
    # @type [Range]
    #
    LCCN_RANGE = ((LCCN_DIGITS.min-1)..(LCCN_DIGITS.max+1)).freeze

    # A pattern matching any of the expected LCCN prefixes.
    #
    # @type [Regexp]
    #
    LCCN_PREFIX = /^\s*LCCN(:\s*|\s+)/i.freeze

    # A pattern matching the form of an LCCN identifier.
    #
    # @type [Regexp]
    #
    LCCN_IDENTIFIER = /^
      (
        ([\x20_#a-z]{3})?\d{8}[\x20_#]? |
        ([\x20_#a-z]{3})?\d{9}          |
        ([\x20_#a-z]{2})?\d{10}
      )(\/.*)?$
    /ix.freeze

    # A pattern matching the form of a (possibly invalid) LCCN identifier.
    #
    # @type [Regexp]
    #
    LCCN_CANDIDATE = /^
      ([\x20_#a-z]{2,3})?\d{#{LCCN_RANGE.minmax.join(',')}}[\x20_#]?(\/.*)?
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
      lccn?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      remove_prefix(v).rstrip
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the given value appears to include an LCCN.
    #
    # @param [any, nil] v
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(LCCN_PREFIX, '').present? || v.match?(LCCN_CANDIDATE)
    end

    # Extract the base identifier of a possible LCCN.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(LCCN_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def remove_prefix(v)
      v.to_s.sub(LCCN_PREFIX, '')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the value is a valid LCCN.
    #
    # @param [any, nil] v
    #
    def lccn?(v)
      to_lccn(v, log: false).present?
    end

    # If the value is a LCCN return it in a normalized form or *nil* otherwise.
    #
    # @param [any, nil] v
    # @param [Boolean]  log
    #
    # @return [String, nil]
    #
    def to_lccn(v, log: true, **)
      lccn   = identifier(v)
      digits = lccn&.sub(%r{/.*$}, '')&.delete('^0-9')
      if LCCN_DIGITS.include?(digits&.size)
        lccn
      elsif log
        Log.info { "#{__method__}: #{v.inspect} is not a valid LCCN" }
      end
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
