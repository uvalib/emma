# app/types/language_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - DublinCoreFields - Language
#
# "List of codes of the primary language(s) of the work, using the ISO 639-2
# 3-character code."
#
# @see "en.emma.type.generic.language"
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/language                                                 DCMI Metadata Terms Format
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFields/dc_language  JSON schema specification
#
class LanguageType < EnumType

  include IsoLanguage::Methods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Language configuration.
  #
  # @type [Hash{Symbol=>any}]
  #
  CONFIGURATION = GENERIC_TYPES[:language]

  # Languages that appear first in the list.
  #
  # @type [Array<Symbol>]
  #
  PRIMARY = (CONFIGURATION[:_primary]&.map(&:to_sym) || []).freeze

  # All language codes and labels.
  #
  # @type [Hash{Symbol=>String}]
  #
  ALL = CONFIGURATION.reject { |k, _| k.start_with?('_') }.freeze

  # ===========================================================================
  # :section: IsoLanguage::Methods overrides
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

  # Return the associated three-letter language code.
  #
  # @param [any, nil] v               Default: #value.
  #
  # @return [String, nil]
  #
  def code(v = nil)
    v ||= value
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  define_enumeration do
    primary, secondary = partition_hash(ALL, *PRIMARY)
    primary.merge(secondary)
  end

end

__loading_end(__FILE__)
