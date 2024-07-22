# app/types/upc.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# UPC identifier.
#
class Upc < PublicationIdentifier

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

    # A valid UPC has at least this many digits.
    #
    # Some forms have supplemental digits in addition to the base UPC number.
    #
    # @type [Integer]
    #
    UPC_DIGITS = 12

    # If a value has a number of digits within this range it could be either a
    # valid UPC or intended as an UPC but with one too few or one too many
    # digits.
    #
    # @type [Range]
    #
    CANDIDATE_RANGE = ((UPC_DIGITS-1)..(UPC_DIGITS+1)).freeze

    # A pattern matching any of the expected UPC prefixes.
    #
    # @type [Regexp]
    #
    UPC_PREFIX = /^\s*UPC(:\s*|\s+)/i.freeze

    # Pattern fragment for a valid separator between groups of UPC digits.
    #
    # @type [String]
    #
    SEPARATOR = '[\x20[:punct:]]'

    # A pattern matching the form of a UPC identifier.
    #
    # @type [Regexp]
    #
    UPC_IDENTIFIER = /^(\d#{SEPARATOR}*){#{UPC_DIGITS}}$/.freeze

    # A pattern matching the form of a (possibly invalid) UPC identifier.
    #
    # @type [Regexp]
    #
    UPC_CANDIDATE =
      /^(\d#{SEPARATOR}*){#{CANDIDATE_RANGE.minmax.join(',')}}$/.freeze

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      upc?(v)
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

    # Indicate whether the given value appears to include a UPC.
    #
    # @param [any, nil] v
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(UPC_PREFIX, '').present? || v.match?(UPC_CANDIDATE)
    end

    # Extract the base identifier of a possible UPC.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(UPC_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def remove_prefix(v)
      v.to_s.sub(UPC_PREFIX, '')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the value is a valid UPC.
    #
    # @param [any, nil] v
    #
    def upc?(v)
      to_upc(v, log: false, validate: true).present?
    end

    # If the value is a UPC return it in a normalized form or *nil* otherwise.
    #
    # @param [any, nil] v
    # @param [Boolean]  log
    # @param [Boolean]  validate      If *true*, return *nil* if the checksum
    #                                   provided in *v* is invalid.
    #
    # @return [String, nil]
    #
    def to_upc(v, log: true, validate: false, **)
      upc = identifier(v)&.delete('^0-9') || ''
      if upc.size >= UPC_DIGITS
        last   = UPC_DIGITS - 1 # Position of the check digit.
        digits = upc[0..(last-1)]
        final  = upc[last]
        added  = upc[(last+1)..]
        # noinspection RubyMismatchedArgumentType
        check  = checksum(digits)
        if !validate || (check == final)
          "#{digits}#{check}#{added}"
        elsif log
          err = "check digit should be #{check}"
          Log.info { "#{__method__}: #{v.inspect}: #{err}" }
        end
      elsif log
        Log.info { "#{__method__}: #{v.inspect}: not a valid UPC" }
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Calculate the UPC checksum for the supplied array of digits.
    #
    # @param [String, Array<String,Integer>] digits
    #
    # @return [String]                  Single-character decimal digit.
    #
    def checksum(digits)
      digits = digits.split('') if digits.is_a?(String)
      check  = UPC_DIGITS - 1 # Position of the check digit.
      total  =
        (0..(check-1)).sum do |index|
          weight = (index % 2).zero? ? 3 : 1
          digits[index].to_i * weight
        end
      remainder = total % 10
      ((10 - remainder) % 10).to_s
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
