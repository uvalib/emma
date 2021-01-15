# app/records/concerns/api/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# =============================================================================
# Definitions of new fundamental "types"
# =============================================================================

public

#--
# noinspection RubyConstantNamingConvention
#++
Boolean = Axiom::Types::Boolean

# Base class for custom scalar types.
#
class ScalarType

  # The value wrapped by this instance.
  #
  # @return [String, nil]
  #
  attr_reader :value

  delegate_missing_to :value

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [*, nil] v                 Optional initial value.
  #
  def initialize(v = nil, *)
    set(v)
  end

  # Assign a new value to the instance.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def value=(v)
    set(v)
  end

  # Assign a new value to the instance.
  #
  # @param [*, nil] v
  #
  # @return [String]
  #
  def set(v)
    unless v.nil?
      @value = normalize(v)
      @value = nil unless valid?(@value)
      Log.error { "#{self.class}: invalid value: #{v.inspect}" } if @value.nil?
    end
    @value ||= default
  end

  # Indicate whether the instance is valid, or indicate whether *v* would be a
  # valid value.
  #
  # @param [*, nil] v
  #
  def valid?(v = nil)
    self.class.valid?(v || @value)
  end

  # Return the string representation of the instance value.
  #
  # @return [String]
  #
  def to_s
    @value.to_s
  end

  # Return the inspection of the instance value.
  #
  # @return [String]
  #
  def inspect
    "(#{to_s.inspect})"
  end

  # The default value for this instance.
  #
  # @return [String]
  #
  def default
    self.class.default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def normalize(v)
    self.class.normalize(v)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Default value for items of this type.
  #
  # @return [String]
  #
  def self.default
    ''
  end

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*, nil] v
  #
  def self.valid?(v)
    !v.nil?
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def self.normalize(v)
    v.to_s.strip
  end

end

# ISO 8601 duration.
#
class IsoDuration < ScalarType

  # Valid values for this type match this pattern.
  #
  # @type [Regexp]
  #
  PATTERN = /^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?)?$/

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*, nil] v
  #
  def self.valid?(v)
    normalize(v).match?(PATTERN)
  end

end

# ISO 8601 general date.
#
class IsoDate < ScalarType

  # Valid values for this type match this pattern one of these patterns.
  #
  # @type [Hash{Symbol=>Regexp}]
  #
  PATTERN = {
    year:  /^\d{4}$/,
    day:   /^\d{4}-\d\d-\d\d$/,
    exact: /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dTZD$/
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the instance represents a year value, or indicate whether
  # *v* represents a year value.
  #
  # @param [*, nil] v
  #
  def year?(v = nil)
    self.class.year?(v || @value)
  end

  # Indicate whether the instance represents a day value, or indicate whether
  # *v* represents a day value.
  #
  # @param [*, nil] v
  #
  def day?(v = nil)
    self.class.day?(v || @value)
  end

  # Indicate whether the instance represents a full ISO 8601 date value, or
  # indicate whether *v* represents a full ISO 8601 date value.
  #
  # @param [*, nil] v
  #
  def exact?(v = nil)
    self.class.exact?(v || @value)
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*, nil] v
  #
  def self.valid?(v)
    v = normalize(v)
    PATTERN.any? { |_, pattern| v.match?(pattern) }
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Indicate whether *v* represents a year value.
  #
  # @param [*, nil] v
  #
  def self.year?(v)
    normalize(v).match?(PATTERN[:year])
  end

  # Indicate whether *v* represents a day value.
  #
  # @param [*, nil] v
  #
  def self.day?(v)
    normalize(v).match?(PATTERN[:day])
  end

  # Indicate whether *v* represents a full ISO 8601 date value.
  #
  # @param [*, nil] v
  #
  def self.exact?(v)
    normalize(v).match?(PATTERN[:exact])
  end

end

# ISO 8601 year.
#
class IsoYear < IsoDate

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*, nil] v
  #
  def self.valid?(v)
    year?(v)
  end

end

# ISO 8601 day.
#
class IsoDay < IsoDate

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*, nil] v
  #
  def self.valid?(v)
    day?(v)
  end

end

# ISO 639-2 alpha-3 language code.
#
class IsoLanguage < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*, nil] v
  #
  def self.valid?(v)
    v = normalize(v)
    ISO_639.find_by_code(v).present?
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  protected

  # Transform *v* into a valid form.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def self.normalize(v)
    find(v)&.alpha3 || super(v)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # find_language
  #
  # @param [String] value
  #
  # @return [ISO_639, nil]
  #
  def self.find(value)
    # @type [Array<ISO_639>] entries
    entries = ISO_639.search(value = value.to_s.strip.downcase)
    if entries.size <= 1
      entries.first
    else
      entries.find do |entry|
        (value == entry.alpha3) || (value == entry.english_name.downcase)
      end
    end
  end

end

# Base class for enumeration scalar types.
#
class EnumType < ScalarType

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Assign a new value to the instance.
  #
  # @param [*, nil] v
  #
  # @return [String]
  #
  def set(v)
    unless v.nil?
      @value = normalize(v)
      @value = nil unless valid?(@value)
      Log.warn { "#{type}: #{v.inspect}: not in #{values}" } if @value.nil?
    end
    @value ||= default
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Indicate whether *v* would be a valid value for an item of this type.
  #
  # @param [*, nil] v
  #
  def self.valid?(v)
    v = normalize(v)
    values.include?(v)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of the represented enumeration type.
  #
  # @return [Symbol]
  #
  def type
    self.class.type
  end

  # The enumeration values associated with the instance.
  #
  # @return [Array<String>]
  #
  def values
    self.class.values
  end

  # The value/label pairs associated with the instance.
  #
  # @return [Hash]
  #
  def pairs
    self.class.pairs
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The name of the represented enumeration type.
  #
  # @return [Symbol]
  #
  def self.type
    self.to_s.to_sym
  end

  # The enumeration values associated with the subclass.
  #
  # @return [Array<String>]
  #
  def self.values
    enumerations.dig(type, :values)
  end

  # The value/label pairs associated with the subclass.
  #
  # @return [Hash]
  #
  def self.pairs
    enumerations.dig(type, :pairs)
  end

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # The default value associated with this enumeration type.  If no default is
  # explicitly defined the initial value is returned.
  #
  # @return [String]
  #
  def self.default
    entry = enumerations[type]
    entry[:default] || entry[:values]&.first
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Called from API record definitions to provide this base class with the
  # values that will be accessed implicitly from subclasses.
  #
  # @param [Hash{Symbol=>Hash}] new_entries
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def self.add_enumerations(new_entries)
    new_entries ||= {}
    new_entries =
      new_entries.transform_values do |cfg|
        if cfg.is_a?(Hash)
          default = cfg[:_default].presence
          pairs   = cfg.except(:_default).stringify_keys
          values  = pairs.keys
        else
          default = nil
          values  = Array.wrap(cfg).map(&:to_s)
          pairs   = values.map { |v| [v, v] }.to_h
        end
        { values: values, pairs: pairs, default: default }.compact
      end
    enumerations.merge!(new_entries)
  end

  # Enumeration definitions accumulated from API records.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # == Implementation Notes
  # This needs to be a class variable so that all subclasses reference the same
  # set of values.
  #
  def self.enumerations
    # noinspection RubyClassVariableUsageInspection
    @@enumerations ||= {}
  end

  # The values for an enumeration.
  #
  # @param [Symbol, String] entry
  #
  # @return [Array<String>]
  #
  def self.values_for(entry)
    enumerations.dig(entry.to_sym, :values)
  end

  # The value/label pairs for an enumeration.
  #
  # @param [Symbol, String] entry
  #
  # @return [Hash]
  #
  def self.pairs_for(entry)
    enumerations.dig(entry.to_sym, :pairs)
  end

end

# =============================================================================
# Module definition
# =============================================================================

public

# Shared values and methods.
#
module Api::Common

  # ===========================================================================
  # Common configuration values - Deployments
  # ===========================================================================

  public

  # Values associated with each deployment type.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see 'en.emma.application.deployment' in config/locales/en.yml
  #
  #--
  # noinspection RailsI18nInspection
  #++
  DEPLOYMENT = I18n.t('emma.application.deployment').deep_freeze

  # Table of deployment names.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #DEPLOYMENT
  #
  DEPLOYMENT_MAP =
    DEPLOYMENT.transform_values { |config| config[:name] }.deep_freeze

  # ===========================================================================
  # Common configuration values - EmmaRepository
  # ===========================================================================

  public

  # The default repository for uploads.
  #
  # @type [String]
  #
  # @see 'en.emma.repository._default' in config/locales/repository.en.yml
  #
  DEFAULT_REPOSITORY = I18n.t('emma.repository._default').freeze

  # Values associated with each source repository.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see 'en.emma.repository' in config/locales/repository.en.yml
  #
  #--
  # noinspection RailsI18nInspection
  #++
  REPOSITORY =
    I18n.t('emma.repository').reject { |k, _|
      k.to_s.start_with?('_')
    }.deep_freeze

  # Table of repository names.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #REPOSITORY
  #
  REPOSITORY_MAP =
    REPOSITORY
      .transform_values { |config| config[:name] }
      .merge!(_default: DEFAULT_REPOSITORY)
      .deep_freeze

  # ===========================================================================
  # Common configuration values - CategoriesType
  # ===========================================================================

  public

  # Bookshare category codes and names.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see 'en.emma.categories' in config/locale/types.en.yml
  #
  #--
  # noinspection RailsI18nInspection
  #++
  CATEGORY = I18n.t('emma.categories', default: {}).deep_freeze

  # Table of Bookshare category names.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #CATEGORY
  #
  CATEGORY_MAP = CATEGORY.map { |_, v| [v.to_sym, v.to_s] }.to_h.deep_freeze

  # ===========================================================================
  # Common configuration values - LanguageType
  # ===========================================================================

  public

  # All language codes and labels.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see 'en.emma.language.list' in config/locale/types.en.yml
  #
  #--
  # noinspection RailsI18nInspection
  #++
  LANGUAGE = I18n.t('emma.language.list', default: {}).deep_freeze

  # Languages that appear first in the list.
  #
  # @type [Array<Symbol>]
  #
  # @see 'en.emma.language.primary' in config/locale/types.en.yml
  #
  PRIMARY_LANGUAGES =
    I18n.t('emma.language.primary', default: []).map(&:to_sym).freeze

  # Language codes and labels in preferred order.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #PRIMARY_LANGUAGES
  # @see #LANGUAGE
  #
  #--
  # noinspection RailsI18nInspection
  #++
  LANGUAGE_MAP =
    PRIMARY_LANGUAGES
      .map { |k| [k, LANGUAGE[k]] }.to_h
      .merge(LANGUAGE.except(*PRIMARY_LANGUAGES))
      .deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  EnumType.add_enumerations(Deployment:     DEPLOYMENT_MAP)
  EnumType.add_enumerations(EmmaRepository: REPOSITORY_MAP)
  EnumType.add_enumerations(CategoriesType: CATEGORY_MAP)
  EnumType.add_enumerations(LanguageType:   LANGUAGE_MAP)

end

# =============================================================================
# Generate top-level classes associated with each enumeration entry so that
# they can be referenced without prepending a namespace.
# =============================================================================

public

# @see Api::Common#DEPLOYMENT_MAP
class Deployment < EnumType; end

# @see Api::Common#REPOSITORY_MAP
class EmmaRepository < EnumType; end

# @see Api::Common#CATEGORY_MAP
class CategoriesType < EnumType; end

# @see Api::Common#LANGUAGE_MAP
class LanguageType < EnumType; end

__loading_end(__FILE__)
