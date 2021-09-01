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
  # @see file:config/locales/types/search.en.yml *en.emma.search.type*
  #
  #--
  # noinspection RailsI18nInspection
  #++
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

# PublicationIdentifier
#
# ISBN-10   10 digits
# ISBN-13   13 digits
# ISSN      8  digits
# OCLC      8+ digits
# UPC       12 digits
#
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3#/PublicationIdentifier  Search API documentation
#
class PublicationIdentifier < ScalarType

  # The standard identifier types.
  #
  # @type [Array<Symbol>]
  #
  TYPES = %i[isbn issn oclc lccn upc].freeze

  # Include type-specific logic.
  TYPES.each do |type|
    type = type.to_s.capitalize
    mod  = "#{type}Helper".safe_constantize
    next unless mod.present?
    send(:include, mod)
    send(:extend,  mod)
  end

  # Valid values for this type match this pattern.
  #
  # @type [Regexp]
  #
  PATTERN = /^(#{TYPES.join('|')}):[0-9X]{8,14}$/i

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def type
    prefix.to_sym
  end

  # The identifier type portion of the value.
  #
  # @return [String]
  #
  def prefix
    value.sub(/^([^:]+):.*$/, '\1')
  end

  # The identifier number portion of the value.
  #
  # @return [String]
  #
  def number
    value.sub(/^[^:]+:(.*)$/, '\1')
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Type-cast an object to a PublicationIdentifier.
  #
  # @param [*] obj                    Value to use or transform.
  #
  # @return [PublicationIdentifier]
  # @return [nil]                     If *obj* is not a valid identifier.
  #
  def self.cast(obj)
    obj.is_a?(PublicationIdentifier) ? obj : create(obj) if obj.present?
  end

  # Create a new instance.
  #
  # @param [*] v                      Optional initial value.
  #
  # @return [PublicationIdentifier]
  # @return [nil]                     If *v* is not a valid identifier.
  #
  def self.create(v, *)
    return if v.blank?
    return v.dup if v.is_a?(PublicationIdentifier)
    type = v.to_s.strip.sub(/^\s*([^:]+)\s*:.*$/, '\1').downcase
    type = type.presence&.safe_constantize
    return type.new(v) if type
    Isbn.new(v).tap { |r| return r if r.valid? } if contains_isbn?(v)
    Issn.new(v).tap { |r| return r if r.valid? } if contains_issn?(v)
    Upc.new(v).tap  { |r| return r if r.valid? } if contains_upc?(v)
    Lccn.new(v).tap { |r| return r if r.valid? } if contains_lccn?(v)
    Oclc.new(v).tap { |r| return r if r.valid? } if contains_oclc?(v)
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Return the string representation of the instance value.
  #
  # @return [String]
  #
  def to_s
    "#{prefix}:#{number}"
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def self.normalize(v)
    v.to_s.strip.downcase.sub(/^([^:]+)[:\s]+/, '\1:')
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    normalize(v).match?(PATTERN)
  end

end

# ISBN identifier.
#
class Isbn < PublicationIdentifier

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def type
    self.class.type
  end

  # The identifier type portion of the value.
  #
  # @return [String]
  #
  def prefix
    type.to_s
  end

  # The identifier number portion of the value.
  #
  # @return [String]
  #
  def number
    value
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def self.normalize(v)
    remove_isbn_prefix(v)
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    isbn?(v)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def self.type
    @type ||= self.to_s.downcase.to_sym
  end

end

# ISSN identifier.
#
class Issn < PublicationIdentifier

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def type
    self.class.type
  end

  # The identifier type portion of the value.
  #
  # @return [String]
  #
  def prefix
    type.to_s
  end

  # The identifier number portion of the value.
  #
  # @return [String]
  #
  def number
    value
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def self.normalize(v)
    remove_issn_prefix(v)
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    issn?(v)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def self.type
    @type ||= self.to_s.downcase.to_sym
  end

end

# OCLC identifier.
#
class Oclc < PublicationIdentifier

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def type
    self.class.type
  end

  # The identifier type portion of the value.
  #
  # @return [String]
  #
  def prefix
    type.to_s
  end

  # The identifier number portion of the value.
  #
  # @return [String]
  #
  def number
    value
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def self.normalize(v)
    remove_oclc_prefix(v)
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    oclc?(v)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def self.type
    @type ||= self.to_s.downcase.to_sym
  end

end

# LCCN identifier.
#
class Lccn < PublicationIdentifier

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def type
    self.class.type
  end

  # The identifier type portion of the value.
  #
  # @return [String]
  #
  def prefix
    type.to_s
  end

  # The identifier number portion of the value.
  #
  # @return [String]
  #
  def number
    value
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def self.normalize(v)
    remove_lccn_prefix(v)
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    lccn?(v)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def self.type
    @type ||= self.to_s.downcase.to_sym
  end

end

# UPC identifier.
#
class Upc < PublicationIdentifier

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def type
    self.class.type
  end

  # The identifier type portion of the value.
  #
  # @return [String]
  #
  def prefix
    type.to_s
  end

  # The identifier number portion of the value.
  #
  # @return [String]
  #
  def number
    value
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def self.normalize(v)
    super # TODO: UPC normalize
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    upc?(v)
    v.to_s.remove(/[^\d]/).size >= 12 # TODO: UPC validity
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @return [Symbol]
  #
  def self.type
    @type ||= self.to_s.downcase.to_sym
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

# "Feature of the format used by this instance of this work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.FormatFeature*
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3#/formatFeature                                                          HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/emma_formatFeature   JSON schema specification
#
class FormatFeature < EnumType
end

# "Ownership-based usage rights"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.Rights*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/dc_rights  JSON schema specification
#
class Rights < EnumType
end

# "Source of this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.Provenance*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/dc_provenance  JSON schema specification
#
class Provenance < EnumType
end

# "Format of this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.DublinCoreFormat*
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3#/format                                         HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/DublinCoreFormat  JSON schema specification
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/format                                        DCMI Metadata Terms Format
#
class DublinCoreFormat < EnumType
end

# "Type of this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.DcmiType*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/dc_type  JSON schema specification
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/type                                                      DCMI Metadata Terms Type
#
class DcmiType < EnumType
end

# "Accessibility features of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yFeature*
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.3#/accessibilityFeature                                                       HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/s_accessibilityFeature   JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11yFeature < EnumType
end

# "Accessibility controls of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yControl*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/s_accessibilityControl   JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11yControl < EnumType
end

# "Accessibility hazards of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yHazard*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/s_accessibilityControl   JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11yHazard < EnumType
end

# "Accessibility APIs of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yAPI*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/s_accessibilityAPI       JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
# == Usage Notes
# Because only ever has the value of "ARIA", it is generally ignored.
#
class A11yAPI < EnumType
end

# "How the user can perceive this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yAccessMode*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/s_accessMode             JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11yAccessMode < EnumType
end

# "A list of single or combined access modes that are sufficient to understand"
# "all the intellectual content of a resource"
#
# @see "en.emma.search.type.A11ySufficient"
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.3#/components/schemas/MetadataCommonRecord/s_accessModeSufficient   JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11ySufficient < EnumType
end

# SearchSort
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.SearchSort*
#
class SearchSort < EnumType
end

# RemediationStatus
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.RemediationStatus*
#
class RemediationStatus < EnumType
end

# SeriesType
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.SeriesType*
#
class SeriesType < EnumType
end

# TextQuality
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.TextQuality*
#
class TextQuality < EnumType
end

# TrueFalse
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.TrueFalse*
#
class TrueFalse < EnumType
end

__loading_end(__FILE__)
