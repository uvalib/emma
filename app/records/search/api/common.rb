# app/records/search/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared values and methods.
#
# @see Api::Common
#
module Search::Api::Common

  include Api::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Type configurations.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/types/search.en.yml
  #
  CONFIGURATION = I18n.t('emma.search.type').deep_freeze

  # Enumeration scalar type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see #CONFIGURATION
  #
  ENUMERATIONS =
    CONFIGURATION
      .transform_values { |cfg| cfg.except(:_default).keys.map(&:to_s) }
      .deep_freeze

  # Enumeration type names.
  #
  # @type [Array<Symbol>]
  #
  # @see #CONFIGURATION
  #
  ENUMERATION_TYPES = CONFIGURATION.keys.freeze

  # Enumeration default values.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #CONFIGURATION
  #
  ENUMERATION_DEFAULTS =
    CONFIGURATION.transform_values { |cfg| cfg[:_default] || '' }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  EnumType.add_enumerations(CONFIGURATION)

end

# =============================================================================
# Definitions of new fundamental "types"
# =============================================================================

public

# Publication Identifier
#
# === API description
# The lowercase scheme and identifier for a publication.  For example,
# isbn:97800110001. Only alphanumeric characters are accepted. No spaces or
# other symbols are accepted. Dashes will be stripped from the stored
# identifier. Accepted schemes are ISBN, ISSN, LCCN, UPC, OCLC, and DOI.
#
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/PublicationIdentifier                   JSON schema specification
#
class PublicationIdentifier < ScalarType

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include ScalarType::Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The subclass of PublicationIdentifier.
    #
    # @return [Class<PublicationIdentifier>]
    #
    def identifier_subclass
      self_class
    end

    # class_type
    #
    # @return [Symbol]
    #
    def class_type
      identifier_subclass.safe_const_get(:TYPE) || :unknown
    end

    # class_prefix
    #
    # @return [String]
    #
    def class_prefix
      identifier_subclass.safe_const_get(:PREFIX) || '???'
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The name of the represented identifier type.
    #
    # @param [Any, nil] v
    #
    # @return [Symbol]
    #
    def type(v = nil)
      v.nil? && class_type || v.try(:class_type) || prefix(v).to_sym
    end

    # The identifier type portion of the value.
    #
    # @param [Any, nil] v
    #
    # @return [String]
    #
    def prefix(v = nil)
      v.nil? && class_prefix || v.try(:class_prefix) || parts(v).first
    end

    # The identifier number portion of the value.
    #
    # @param [String, Any, nil] v
    #
    # @return [String]
    #
    def number(v)
      normalize(v)
    end

    # Split a value into a type prefix and a number.
    #
    # @param [String, Any, nil] v
    #
    # @return [Array<(String, String)>]
    #
    def parts(v)
      s = v.to_s.strip
      n = remove_prefix(s)
      p = (n.blank? || (n == s)) ? '' : s.delete_suffix(n).sub(/:?\s*$/, '')
      return p, n
    end

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [String, Any, nil] v
    #
    def valid?(v)
      normalize(v).present?
    end

    # Transform *v* into a valid form.
    #
    # @param [String, Any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      remove_prefix(v).rstrip
    end

    # Type-cast a value to a PublicationIdentifier.
    #
    # @param [*]       v              Value to use or transform.
    # @param [Boolean] invalid        If *true* allow invalid value.
    #
    # @return [PublicationIdentifier] Possibly invalid identifier.
    # @return [nil]                   If *v* is not any kind of identifier.
    #
    def cast(v, invalid: false, **)
      v = create(v) unless v.is_a?(identifier_subclass)
      v if invalid || v&.valid?
    end

    # Create a new instance.
    #
    # @param [String, nil]    v       Identifier number.
    # @param [Symbol, String] type    Determined from *v* if missing.
    #
    # @return [PublicationIdentifier] Possibly invalid identifier.
    # @return [nil]                   If *v* is not any kind of identifier.
    #
    def create(v, type = nil, **)
      prefix, value = type ? [type, v] : parts(v)
      return                       if value.blank?
      value = "#{prefix}:#{value}" if prefix.present?
      identifier_classes.find { |c| c.candidate?(value) }&.new(value)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether a value could be used as a PublicationIdentifier.
    #
    # @param [String, Any, nil] v
    #
    def candidate?(v)
      identifier(v).present?
    end

    # Extract the base identifier of a possible PublicationIdentifier.
    #
    # @param [String, Any, nil] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      remove_prefix(v).rstrip.presence
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [String, Any, nil] v
    #
    # @return [String]
    #
    def remove_prefix(v)
      v.to_s.sub(/^\s*[a-z]+[\x20:]\s*/i, '')
    end

    # Indicate whether the given value has the characteristic prefix.
    #
    # @param [String, Any, nil] v
    #
    def prefix?(v)
      v != remove_prefix(v)
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

  # The identifier number portion of the value.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [String, nil]
  #
  def number(v = nil)
    v ? super : value
  end

  # Split a value into a type prefix and a number.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [Array<(String, String)>]
  #
  def parts(v = nil)
    v ? super : [prefix, number]
  end

  # Indicate whether the instance is valid.
  #
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    super(v || value)
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Assign a new value to the instance, allowing for the possibility of an
  # invalid identifier value.
  #
  # If *v* has the wrong kind of prefix then the result will be blank (and
  # therefore invalid).
  #
  # @param [Any, nil] v
  #
  # @return [String]
  #
  def set(v)
    @value = (v.blank? || (!prefix?(v) && v.include?(':'))) ? '' : normalize(v)
  end

  # Return the string representation of the instance value.
  #
  # @return [String]
  #
  def to_s
    parts.join(':')
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Identifier subclasses.
  #
  # @return [Array<Class<PublicationIdentifier>>]
  #
  def self.identifier_classes
    # noinspection RbsMissingTypeSignature
    @identifier_classes ||= [Doi, Isbn, Issn, Upc, Oclc, Lccn]
  end

  # Identifier type names.
  #
  # @return [Array<Symbol>]
  #
  def self.identifier_types
    # noinspection RbsMissingTypeSignature
    @identifier_types ||= identifier_classes.map(&:type)
  end

  # Table of identifier subclasses.
  #
  # @return [Hash{Symbol=>Class<PublicationIdentifier>}]
  #
  def self.subclass_map
    # noinspection RbsMissingTypeSignature
    @subclass_map ||= identifier_classes.map { |c| [c.type, c] }.to_h
  end

  # Retrieve the matching identifier subclass.
  #
  # @param [Symbol, String, Class<PublicationIdentifier>, nil] type
  #
  # @return [Class<PublicationIdentifier>, nil]
  #
  def self.subclass(type = nil)
    # noinspection RubyMismatchedReturnType
    case type
      when Symbol, String then subclass_map[type.to_sym]
      when Class          then type if type < PublicationIdentifier
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create an array of identifier candidate strings.
  #
  # @param [String, PublicationIdentifier, Array, nil] value
  #
  # @return [Array<String>]
  #
  def self.split(value)
    Array.wrap(value).join("\n").split(/ *[,;|\t\n] */).compact_blank!
  end

  # Create an array of identifier instances from candidate string(s).
  #
  # @param [String, PublicationIdentifier, Array, nil] value
  # @param [Boolean]                                   invalid
  #
  # @return [Array<PublicationIdentifier>]
  # @return [Array<PublicationIdentifier,nil>]          If *invalid* is *true*.
  #
  def self.objects(value, invalid: true)
    result = split(value).map! { |id| cast(id, invalid: invalid) }
    invalid ? result : result.compact
  end

  # Create a table of identifier instances from candidate string(s).
  #
  # @param [String, PublicationIdentifier, Array, nil] value
  # @param [Boolean]                                   invalid
  #
  # @return [Hash{String=>PublicationIdentifier}]
  # @return [Hash{String=>PublicationIdentifier,nil}]   If *invalid* is *true*.
  #
  def self.object_map(value, invalid: true)
    result = split(value).map! { |id| [id, cast(id, invalid: invalid)] }.to_h
    invalid ? result : result.compact
  end

end

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
    # @param [String, Any] v
    #
    def valid?(v)
      isbn?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [String, Any] v
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
    # @param [String, Any] v
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
    # @param [String, Any] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(ISBN_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [String, Any] v
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
    # @param [String] v
    #
    def isbn?(v)
      isbn = identifier(v) or return false
      checksum(isbn) == isbn.last
    end

    # Indicate whether the string is a valid ISBN-13.
    #
    # @param [String] v
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
    # @param [String] v
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
    # @param [String]  v
    # @param [Hash]    opt              Passed to #to_isbn13.
    #
    # @return [String, nil]
    #
    def to_isbn(v, **opt)
      to_isbn13(v, **opt)
    end

    # If the value is an ISBN-13; if it is an ISBN-10, convert it to the
    # equivalent ISBN-13; otherwise return *nil*.
    #
    # @param [String]  v
    # @param [Boolean] log
    #
    # @return [String, nil]
    #
    def to_isbn13(v, log: true, **)
      digits = identifier(v)&.delete('^0-9xX')
      isbn10 = (digits&.size == ISBN_10_DIGITS)
      check  = digits&.last&.upcase
      digits = digits&.slice(0...-1)
      valid  = digits && (check == checksum(digits))
      if isbn10 && valid
        # noinspection RubyMismatchedArgumentType
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
    # @param [String]  v
    # @param [Boolean] log
    #
    # @return [String, nil]
    #
    def to_isbn10(v, log: true, **)
      digits = identifier(v)&.delete('^0-9xX')
      isbn13 = (digits&.size == ISBN_13_DIGITS)
      check  = digits&.last&.upcase
      digits = digits&.slice(0...-1)
      valid  = digits && (check == checksum(digits))
      if isbn13 && valid && digits&.delete_prefix!('978')
        # noinspection RubyMismatchedArgumentType
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
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    super(v || value)
  end

  # Indicate whether the instance is a valid ISBN-13.
  #
  # @param [String, nil] v            Default: #value.
  #
  def isbn13?(v = nil)
    super(v || value)
  end

  # Indicate whether the instance is a valid ISBN-10.
  #
  # @param [String, nil] v            Default: #value.
  #
  def isbn10?(v = nil)
    super(v || value)
  end

end

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
    # @param [String, Any] v
    #
    def valid?(v)
      issn?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [String, Any] v
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
    # @param [String, Any] v
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(ISSN_PREFIX, '').present? || v.match?(ISSN_CANDIDATE)
    end

    # Extract the base identifier of a possible ISSN.
    #
    # @param [String, Any] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(ISSN_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [String, Any] v
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
    # @param [String] v
    #
    def issn?(v)
      to_issn(v, log: false, validate: true).present?
    end

    # If the value is an ISSN return it in a normalized form or *nil* otherwise
    #
    # @param [String]  v
    # @param [Boolean] log
    # @param [Boolean] validate         If *true*, return *nil* if the
    #                                     checksum provided in *v* is invalid.
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
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    super(v || value)
  end

end

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
      OCLC_FORMAT.values.flatten.compact.then { |a| (a.min..a.max) }.freeze

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

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [Any] v
    #
    def valid?(v)
      oclc?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [Any] v
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
    # @param [String, Any] v
    #
    # === Usage Notes
    # If *v* matches #OCLC_PREFIX then the method returns *true* even if the
    # actual number is invalid; the caller is expected to differentiate between
    # valid and invalid cases and handle each appropriately.  The one exception
    # is if the prefix is "on" -- here the remainder must be a valid OCLC
    # number (otherwise words like "one" are interpreted as "oclc:e").
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(OCLC_PREFIX, '')
      v.match?(OCLC_CANDIDATE)
    end

    # Extract the base identifier of a possible OCN.
    #
    # @param [String, Any] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(OCLC_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [String, Any] v
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
    # @param [String] v
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
    # @param [String]  v
    # @param [Boolean] log
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
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    super(v || value)
  end

end

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
    # @param [Any] v
    #
    def valid?(v)
      lccn?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [Any] v
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
    # @param [String, Any] v
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(LCCN_PREFIX, '').present? || v.match?(LCCN_CANDIDATE)
    end

    # Extract the base identifier of a possible LCCN.
    #
    # @param [String, Any] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(LCCN_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [String, Any] v
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
    # @param [String] v
    #
    def lccn?(v)
      to_lccn(v, log: false).present?
    end

    # If the value is a LCCN return it in a normalized form or *nil* otherwise.
    #
    # @param [String]  v
    # @param [Boolean] log
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
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    super(v || value)
  end

end

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
    # @param [String, Any] v
    #
    def valid?(v)
      upc?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [String, Any] v
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
    # @param [String, Any] v
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(UPC_PREFIX, '').present? || v.match?(UPC_CANDIDATE)
    end

    # Extract the base identifier of a possible UPC.
    #
    # @param [String, Any] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(UPC_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [String, Any] v
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
    # @param [String] v
    #
    def upc?(v)
      to_upc(v, log: false, validate: true).present?
    end

    # If the value is a UPC return it in a normalized form or *nil* otherwise.
    #
    # @param [String]  v
    # @param [Boolean] log
    # @param [Boolean] validate         If *true*, return *nil* if the
    #                                     checksum provided in *v* is invalid.
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
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    super(v || value)
  end

end

# DOI identifier.
#
# - UTF-8 Unicode characters
# - Case-insensitive for ASCII Unicode characters
# - Case-sensitive for non-ASCII Unicode characters
#
# @see https://www.doi.org/doi_handbook/2_Numbering.html
#
class Doi < PublicationIdentifier

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

    # A pattern matching any of the expected DOI prefixes.
    #
    # @type [Regexp]
    #
    DOI_PREFIX = %r{^\s*(
      doi(:\s*|\s+) |
      (https?:)?(//)?doi\.org/ |
      (https?:)?(//)?dx\.doi\.org/
    )}ix.freeze

    # A pattern matching the form of an DOI identifier.
    #
    # @type [Regexp]
    #
    DOI_IDENTIFIER = /^10\.\d{4,}(\.d+)*\/.*$/.freeze

    # A pattern matching the form of a (possibly invalid) DOI identifier.
    #
    # @type [Regexp]
    #
    DOI_CANDIDATE = /^10\.\d/.freeze

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [Any] v
    #
    def valid?(v)
      doi?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [Any] v
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

    # Indicate whether the given value appears to include a DOI.
    #
    # @param [String, Any] v
    #
    # === Usage Notes
    # If *v* matches #DOI_PREFIX then the method returns *true* even if the
    # actual number is invalid; the caller is expected to differentiate between
    # valid and invalid cases and handle each appropriately.
    #
    def candidate?(v)
      v = v.to_s.strip
      v.sub!(DOI_PREFIX, '').present? || v.match?(DOI_CANDIDATE)
    end

    # Extract the base identifier of a possible DOI.
    #
    # @param [String, Any] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      v = remove_prefix(v).rstrip
      v if v.match?(DOI_IDENTIFIER)
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [String, Any] v
    #
    # @return [String]
    #
    # === Implementation Notes
    # Accounts for not-quite-valid forms like "doi:https://doi.org/..." by
    # repeating prefix removal.
    #
    def remove_prefix(v)
      v.to_s.sub(DOI_PREFIX, '').sub(DOI_PREFIX, '')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the value is a valid DOI.
    #
    # @param [String] v
    #
    def doi?(v)
      to_doi(v, log: false).present?
    end

    # If the value is a DOI return it in a normalized form or *nil* otherwise.
    #
    # @param [String]  v
    # @param [Boolean] log
    #
    # @return [String, nil]
    #
    def to_doi(v, log: true, **)
      doi = identifier(v) and return doi
      Log.info { "#{__method__}: #{v.inspect} is not a valid DOI" } if log
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
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    super(v || value)
  end

end

# =============================================================================
# Generate top-level classes associated with each enumeration entry so that
# they can be referenced without prepending a namespace.
#
# Values for each class come from the equivalently-name key in
# Search::Api::Common::CONFIGURATION.
# =============================================================================

public

# "Describes the type of work"
#
# @note Rejected for API 0.0.5
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.WorkType*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/EmmaCommonFields/emma_workType            JSON schema specification
#
class WorkType < EnumType
end

# "Feature of the format used by this instance of this work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.FormatFeature*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/EmmaCommonFields/emma_formatFeature       JSON schema specification
#
class FormatFeature < EnumType
end

# =============================================================================
# API schema - DublinCoreFields
# =============================================================================

public

# "Ownership-based usage rights"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.Rights*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFields/dc_rights                JSON schema specification
#
class Rights < EnumType
end

# "Source of this instance of the work"
#
# @note Deprecated with API 0.0.5
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.Provenance*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFields/dc_provenance            JSON schema specification
#
class Provenance < EnumType
end

# "Format of this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.DublinCoreFormat*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFormat                          JSON schema specification
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/format                                                                DCMI Metadata Terms Format
#
class DublinCoreFormat < EnumType
end

# "Type of this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.DcmiType*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFields/dc_type                  JSON schema specification
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/type                                                                  DCMI Metadata Terms Type
#
class DcmiType < EnumType
end

# =============================================================================
# API schema - SchemaOrgFields
# =============================================================================

public

# "Accessibility features of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yFeature*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessibilityFeature    JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                       W3C WebSchemas Accessibility Terms
#
class A11yFeature < EnumType
end

# "Accessibility controls of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yControl*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessibilityControl    JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                       W3C WebSchemas Accessibility Terms
#
class A11yControl < EnumType
end

# "Accessibility hazards of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yHazard*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessibilityHazard     JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                       W3C WebSchemas Accessibility Terms
#
class A11yHazard < EnumType
end

# "Accessibility APIs of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yAPI*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessibilityAPI        JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                       W3C WebSchemas Accessibility Terms
#
# === Usage Notes
# Because only ever has the value of "ARIA", it is generally ignored.
#
class A11yAPI < EnumType
end

# "How the user can perceive this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yAccessMode*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessMode              JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                       W3C WebSchemas Accessibility Terms
#
class A11yAccessMode < EnumType
end

# "A list of single or combined access modes that are sufficient to understand"
# "all the intellectual content of a resource"
#
# @see "en.emma.search.type.A11ySufficient"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessModeSufficient    JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                       W3C WebSchemas Accessibility Terms
#
class A11ySufficient < EnumType
end

# =============================================================================
# API schema - RemediationFields
# =============================================================================

public

# SourceType
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.SourceType*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/RemediationFields/rem_source              JSON schema specification
#
class SourceType < EnumType
end

# RemediatedAspects
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.RemediatedAspects*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/RemediationFields/rem_remediatedAspects   JSON schema specification
#
class RemediatedAspects < EnumType
end

# TextQuality
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.TextQuality*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/RemediationFields/rem_textQquality        JSON schema specification
#
class TextQuality < EnumType
end

# RemediationStatus
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.RemediationStatus*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/RemediationFields/rem_status              JSON schema specification
#
class RemediationStatus < EnumType
end

# =============================================================================
# EMMA Unified Search API
# =============================================================================

public

# SearchSort
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.SearchSort*
# @see https://api.swaggerhub.com/apis/bus/emma-federated-search-api/0.0.5#/paths/search/get/parameters[name=sort]                                 JSON API specification
#
class SearchSort < EnumType
end

# SearchGroup
#
# === API description
# (EXPERIMENTAL) Search results will be grouped by the given field.  Result
# page size will automatically be limited to 10 maximum.  Each result will have
# a number of grouped records provided as children, so the number of records
# returned will be more than 10.  Cannot be combined with sorting by title or
# date.
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.SearchGroup*
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/Group                                     JSON schema specification
#
class SearchGroup < EnumType
end

# =============================================================================
# FRAME metadata
# =============================================================================

public

# SeriesType
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.SeriesType*
#
class SeriesType < EnumType
end

# =============================================================================
# Other
# =============================================================================

public

# TrueFalse
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.TrueFalse*
#
class TrueFalse < EnumType
end

__loading_end(__FILE__)
