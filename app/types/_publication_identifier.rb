# app/types/_publication_identifier.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A generic "standard identifier" for a published work, as well as the base
# class for specific identifier types.
#
# === API description
# The lowercase scheme and identifier for a publication.  For example,
# isbn:97800110001. Only alphanumeric characters are accepted. No spaces or
# other symbols are accepted. Dashes will be stripped from the stored
# identifier. Accepted schemes are ISBN, ISSN, LCCN, UPC, OCLC, and DOI.
#
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/PublicationIdentifier  JSON schema specification
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
    # @param [any, nil] v
    #
    # @return [Symbol]
    #
    def type(v = nil)
      v.nil? && class_type || v.try(:class_type) || prefix(v).to_sym
    end

    # The identifier type portion of the value.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def prefix(v = nil)
      v.nil? && class_prefix || v.try(:class_prefix) || parts(v).first
    end

    # The identifier number portion of the value.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def number(v)
      normalize(v)
    end

    # Split a value into a type prefix and a number.
    #
    # @param [any, nil] v
    #
    # @return [Array(String, String)]
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

    # Indicate whether `*v*` would be a valid value for an item of this type.
    #
    # @param [any, nil] v
    #
    def valid?(v)
      normalize(v).present?
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

    # Type-cast a value to a PublicationIdentifier.
    #
    # @param [any, nil] v             Value to use or transform.
    # @param [Boolean]  invalid       If *true* allow invalid value.
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
    # If *v* is an un-prefixed 10-digit value (which could be interpreted as
    # either an OCLC or an LCCN missing its alphabetic prefix), if the leading
    # digits could indicate a 4-digit year then LCCN is favored.
    #
    # @param [any, nil]       v       Identifier number.
    # @param [Symbol, String] type    Determined from *v* if missing.
    #
    # @return [PublicationIdentifier] Possibly invalid identifier.
    # @return [nil]                   If *v* is not any kind of identifier.
    #
    def create(v, type = nil, **)
      prefix, value = type ? [type, v] : parts(v)
      if value.present?
        value = "#{prefix}:#{value}" if prefix.present?
        candidates = identifier_classes.select { _1.candidate?(value) }
        if candidates.present?
          ambiguous = prefix.blank?
          ambiguous &&= candidates.include?(Oclc) && candidates.include?(Lccn)
          candidates.map! { _1.new(value) }
          valid_candidates = candidates.select(&:valid?)
          if ambiguous && (lccn = valid_candidates.find { _1.is_a?(Lccn) })
            n = lccn.value
            if (n.size == 10) && (n.start_with?('1') || n.start_with?('20'))
              valid_candidates = [lccn]
            end
          end
          valid_candidates.first || candidates.first
        end
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether a value could be used as a PublicationIdentifier.
    #
    # @param [any, nil] v
    #
    def candidate?(v)
      identifier(v).present?
    end

    # Extract the base identifier of a possible PublicationIdentifier.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def identifier(v)
      remove_prefix(v).rstrip.presence
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def remove_prefix(v)
      v.to_s.sub(/^\s*[a-z]+[\x20:]\s*/i, '')
    end

    # Indicate whether the given value has the characteristic prefix.
    #
    # @param [any, nil] v
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
  # @param [any, nil] v               Default: #value.
  #
  # @return [String, nil]
  #
  def number(v = nil)
    v ? super : value
  end

  # Split a value into a type prefix and a number.
  #
  # @param [any, nil] v               Default: #value.
  #
  # @return [Array(String, String)]
  #
  def parts(v = nil)
    v ? super : [prefix, number]
  end

  # Indicate whether the instance is valid.
  #
  # @param [any, nil] v               Default: #value.
  #
  def valid?(v = nil)
    v ||= value
    super
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Assign a new value to the instance, allowing for the possibility of an
  # invalid identifier value.
  #
  # If `*v*` has the wrong kind of prefix then the result will be blank (and
  # therefore invalid).
  #
  # @param [any, nil] v
  #
  # @return [String]
  #
  def set(v, **)
    v = nil if v == EMPTY_VALUE
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
  # == Implementation Notes
  # This value is `PublicationIdentifier.subclasses` but ordered to facilitate
  # PublicationIdentifier::Methods#create.
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
    @subclass_map ||= identifier_classes.map { [_1.type, _1] }.to_h
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
    Array.wrap(value).join("\n").split(/ *[,;|\t\n] */).compact_blank
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
    result = split(value).map! { cast(_1, invalid: invalid) }
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
    result = split(value).map! { [_1, cast(_1, invalid: invalid)] }.to_h
    invalid ? result : result.compact
  end

end

__loading_end(__FILE__)
