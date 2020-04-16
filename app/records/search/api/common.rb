# app/records/search/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/common'

# Shared values and methods.
#
# @see Api::Common
#
module Search::Api::Common

  include ::Api::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Values associated with each source repository.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # noinspection RailsI18nInspection
  REPOSITORY =
    I18n.t('emma.source').reject { |k, _| k.to_s.start_with?('_') }.deep_freeze

  # Type configurations.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # noinspection RailsI18nInspection
  CONFIGURATION =
    I18n.t('emma.search.type').merge(
      EmmaRepository:
        REPOSITORY
          .transform_values { |cfg| cfg[:name] }
          .merge(_default: I18n.t('emma.source._default'))
    ).deep_freeze

  # Enumeration scalar type names and properties.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ENUMERATIONS =
    CONFIGURATION
      .transform_values { |cfg| cfg.except(:_default).keys.map(&:to_s) }
      .deep_freeze

  # Enumeration type names.
  #
  # @type [Array<Symbol>]
  #
  ENUMERATION_TYPES = CONFIGURATION.keys.freeze

  # Enumeration default values.
  #
  # @type [Hash{Symbol=>String}]
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
# ISBN-10   10
# ISBN-13   13
# ISSN      8
# UPC       12
# OCN       >= 8
#
class PublicationIdentifier < ScalarType

  # Valid values for this type match this pattern.
  #
  # @type [RegExp]
  #
  PATTERN = /^(isbn|oclc|upc|issn):[0-9X]{8,14}$/i

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*, nil] v
  #
  # This method overrides:
  # @see ScalarType#valid?
  #
  def self.valid?(v)
    normalize(v).match?(PATTERN)
  end

end

# =============================================================================
# Generate top-level classes associated with each enumeration entry so that
# they can be referenced without prepending a namespace.
# =============================================================================

class EmmaRepository   < EnumType; end
class FormatFeature    < EnumType; end
class Rights           < EnumType; end
class Provenance       < EnumType; end
class DublinCoreFormat < EnumType; end
class DcmiType         < EnumType; end
class A11yFeature      < EnumType; end
class A11yControl      < EnumType; end
class A11yHazard       < EnumType; end
class A11yAPI          < EnumType; end
class A11yAccessMode   < EnumType; end
class A11ySufficient   < EnumType; end
class SearchSort       < EnumType; end

__loading_end(__FILE__)
