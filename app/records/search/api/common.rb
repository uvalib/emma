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
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.4#/PublicationIdentifier  Search API documentation
#
class PublicationIdentifier < ScalarType

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The standard identifier types.
  #
  # @type [Array<Symbol>]
  #
  TYPES = %i[isbn issn oclc lccn upc].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # class_type
    #
    # @return [Symbol]
    #
    def class_type
      safe_const_get(:TYPE) || self.class.safe_const_get(:TYPE)
    end

    # class_prefix
    #
    # @return [String]
    #
    def class_prefix
      safe_const_get(:PREFIX) || self.class.safe_const_get(:PREFIX)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The name of the represented identifier type.
    #
    # @param [String, nil] v
    #
    # @return [Symbol]
    #
    def type(v = nil)
      v ? prefix(v).to_sym : class_type
    end

    # The identifier type portion of the value.
    #
    # @param [String, nil] v
    #
    # @return [String]
    #
    def prefix(v = nil)
      v ? parts(v).first : class_prefix
    end

    # The identifier number portion of the value.
    #
    # @param [String, nil] v
    #
    # @return [String]
    #
    def number(v)
      parts(v).last
    end

    # Split a value into a type prefix and a number.
    #
    # @param [String, nil] v
    #
    # @return [(String, String)]
    #
    def parts(v)
      pre, num = v.to_s.split(':', 2).map(&:strip).presence || ['', '']
      return pre, num if num.present?
      return pre, ''  if pre.match?(/^[a-z]+$/i)
      return '',  pre
    end

    # Strip the characteristic prefix of the including class.
    #
    # @param [String, nil] v
    #
    # @return [String]
    #
    def remove_prefix(v)
      v.to_s.remove(/^\s*#{prefix}\s*:\s*/i)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Type-cast an object to a PublicationIdentifier.
    #
    # @param [*] obj                  Value to use or transform.
    #
    # @return [PublicationIdentifier]
    # @return [nil]                   If *obj* is not a valid identifier.
    #
    def cast(obj)
      obj.is_a?(PublicationIdentifier) ? obj : create(obj) if obj.present?
    end

    # Create a new instance.
    #
    # @param [String] v               Identifier number.
    #
    # @return [PublicationIdentifier]
    # @return [nil]                   If *v* is not a valid identifier.
    #
    def create(v, *)
      prefix, number = parts(v)
      return if number.blank?
      if prefix.present?
        types = [prefix.classify.safe_constantize].compact
      else
        types = [Isbn, Issn, Lccn, Oclc, Upc]
      end
      types.find do |type|
        result = Log.silence { type.new(number) }
        return result if result.valid?
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
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
  # @return [(String, String)]
  #
  def parts(v = nil)
    v ? super : [prefix, number]
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
    parts.join(':')
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
    parts(v.to_s.downcase).join(':')
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    [Isbn, Issn, Lccn, Oclc, Upc].find do |type|
      break true if type.valid?(v)
    end || false
  end

end

# ISBN identifier.
#
class Isbn < PublicationIdentifier

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  PREFIX = name.underscore
  TYPE   = PREFIX.to_sym

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [Symbol]
  #
  def type(v = nil)
    v ? super : TYPE
  end

  # The identifier type portion of the value.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [String]
  #
  def prefix(v = nil)
    v ? super : PREFIX
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
    remove_prefix(v).delete('^0-9xX')
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    IsbnHelper.isbn?(v)
  end

end

# ISSN identifier.
#
class Issn < PublicationIdentifier

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  PREFIX = name.underscore
  TYPE   = PREFIX.to_sym

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [Symbol]
  #
  def type(v = nil)
    v ? super : TYPE
  end

  # The identifier type portion of the value.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [String]
  #
  def prefix(v = nil)
    v ? super : PREFIX
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
    remove_prefix(v).delete('^0-9xX')
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    IssnHelper.issn?(v)
  end

end

# OCLC identifier.
#
class Oclc < PublicationIdentifier

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  PREFIX = name.underscore
  TYPE   = PREFIX.to_sym

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [Symbol]
  #
  def type(v = nil)
    v ? super : TYPE
  end

  # The identifier type portion of the value.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [String]
  #
  def prefix(v = nil)
    v ? super : PREFIX
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
    OclcHelper.to_oclc(v, log: false) || ''
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    OclcHelper.oclc?(v)
  end

end

# LCCN identifier.
#
class Lccn < PublicationIdentifier

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  PREFIX = name.underscore
  TYPE   = PREFIX.to_sym

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [Symbol]
  #
  def type(v = nil)
    v ? super : TYPE
  end

  # The identifier type portion of the value.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [String]
  #
  def prefix(v = nil)
    v ? super : PREFIX
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
    LccnHelper.to_lccn(v, log: false) || ''
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    LccnHelper.lccn?(v)
  end

end

# UPC identifier.
#
class Upc < PublicationIdentifier

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  PREFIX = name.underscore
  TYPE   = PREFIX.to_sym

  # ===========================================================================
  # :section: PublicationIdentifier overrides
  # ===========================================================================

  public

  # The name of the represented identifier type.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [Symbol]
  #
  def type(v = nil)
    v ? super : TYPE
  end

  # The identifier type portion of the value.
  #
  # @param [String, nil] v            Default: #value.
  #
  # @return [String]
  #
  def prefix(v = nil)
    v ? super : PREFIX
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
    remove_prefix(v).delete('^0-9')
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*] v
  #
  def self.valid?(v)
    UpcHelper.upc?(v)
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
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.4#/formatFeature                                                          HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/emma_formatFeature   JSON schema specification
#
class FormatFeature < EnumType
end

# "Ownership-based usage rights"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.Rights*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/dc_rights  JSON schema specification
#
class Rights < EnumType
end

# "Source of this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.Provenance*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/dc_provenance  JSON schema specification
#
class Provenance < EnumType
end

# "Format of this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.DublinCoreFormat*
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.4#/format                                         HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/DublinCoreFormat  JSON schema specification
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/format                                        DCMI Metadata Terms Format
#
class DublinCoreFormat < EnumType
end

# "Type of this instance of the work"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.DcmiType*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/dc_type  JSON schema specification
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/type                                                      DCMI Metadata Terms Type
#
class DcmiType < EnumType
end

# "Accessibility features of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yFeature*
# @see https://app.swaggerhub.com/apis/kden/emma-federated-search-api/0.0.4#/accessibilityFeature                                                       HTML schema documentation
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/s_accessibilityFeature   JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11yFeature < EnumType
end

# "Accessibility controls of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yControl*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/s_accessibilityControl   JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11yControl < EnumType
end

# "Accessibility hazards of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yHazard*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/s_accessibilityControl   JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11yHazard < EnumType
end

# "Accessibility APIs of this instance derived from schema.org"
#
# @see file:config/locales/types/search.en.yml *en.emma.search.type.A11yAPI*
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/s_accessibilityAPI       JSON schema specification
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
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/s_accessMode             JSON schema specification
# @see https://www.w3.org/wiki/WebSchemas/Accessibility#Accessibility_terms_.28Version_2.0.29                                                           W3C WebSchemas Accessibility Terms
#
class A11yAccessMode < EnumType
end

# "A list of single or combined access modes that are sufficient to understand"
# "all the intellectual content of a resource"
#
# @see "en.emma.search.type.A11ySufficient"
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.4#/components/schemas/MetadataCommonRecord/s_accessModeSufficient   JSON schema specification
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
