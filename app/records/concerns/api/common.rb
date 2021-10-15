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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include Emma::Common

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Default value for items of this type.
    #
    # @return [String]
    #
    def default
      ''
    end

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [*] v
    #
    def valid?(v)
      !v.nil?
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Transform *v* into a valid form.
    #
    # @param [*] v
    #
    # @return [String]
    #
    def normalize(v)
      v.to_s.strip
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
  # :section:
  # ===========================================================================

  public

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
  # @param [*] v                      Optional initial value.
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
  # @param [*] v
  #
  # @return [String]
  #
  def set(v)
    unless v.nil?
      @value = normalize(v)
      @value = nil unless valid?(@value)
    end
    @value ||= default
  end

  # ===========================================================================
  # :section: ScalarType::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid, or indicate whether *v* would be a
  # valid value.
  #
  # @param [*] v
  #
  def valid?(v = nil)
    super(v || @value)
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  protected

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

end

# ISO 8601 duration.
#
# @see https://en.wikipedia.org/wiki/ISO_8601#Durations
#
class IsoDuration < ScalarType

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

    # Valid values for this type start with one of these patterns.
    #
    # By the standard, the lowest-order component may be fractional.
    #
    # @type [Hash{Symbol=>Regexp}]
    #
    START_PATTERN = {
      complete: /^(P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+([.,]\d+)?S)?)?)/,
      weeks:    /^(P\d+([.,]\d+)?W)/,
      seconds:  /^(P(\d+Y)?(\d+M)?(\d+D)?T(\d+H)?(\d+M)?\d+([.,]\d+)?S)/,
      minutes:  /^(P(\d+Y)?(\d+M)?(\d+D)?T(\d+H)?\d+([.,]\d+)?M)/,
      hours:    /^(P(\d+Y)?(\d+M)?(\d+D)?T\d+([.,]\d+)?H)/,
      days:     /^(P(\d+Y)?(\d+M)?\d+([.,]\d+)?D)/,
      months:   /^(P(\d+Y)?\d+([.,]\d+)?M)/,
      years:    /^(P\d+([.,]\d+)?Y)/,
    }.deep_freeze

    # Valid values for this type match one of these patterns.
    #
    # @type [Hash{Symbol=>Regexp}]
    #
    MATCH_PATTERN =
      START_PATTERN.transform_values { |pattern|
        Regexp.new(pattern.source + '$')
      }.deep_freeze

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [*] v
    #
    def valid?(v)
      normalize(v).present?
    end

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    protected

    # Transform *v* into a valid form.
    #
    # @param [String, Date, Time, IsoDate, *] v
    #
    # @return [String]
    #
    def normalize(v)
      # noinspection RubyMismatchedReturnType
      case v
        when ActiveSupport::Duration then return from_duration(v)
        when IsoDuration             then return v.to_s
        else                              v = v.to_s
      end
      MATCH_PATTERN.any? { |pattern| v.match?(pattern) } ? v : ''
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Translate an ActiveSupport::Duration into an ISO 8601 duration.
    #
    # @param [ActiveSupport::Duration] duration
    #
    # @return [String]
    #
    def from_duration(duration)
      years, months, weeks, days, hours, mins, secs =
        duration.parts.values_at(*ActiveSupport::Duration::PARTS)
      weeks, days = fractional(weeks, days, 7) if weeks.is_a?(Float)
      if weeks && (days || duration.parts.except(:weeks).present?)
        days  = (days || 0) + (weeks * 7)
        weeks = nil
      end
      years,  months = fractional(years,  months, 12) if years.is_a?(Float)
      months, days   = fractional(months, days,   30) if months.is_a?(Float)
      days,   hours  = fractional(days,   hours,  24) if days.is_a?(Float)
      hours,  mins   = fractional(hours,  mins,   60) if hours.is_a?(Float)
      mins,   secs   = fractional(mins,   secs,   60) if mins.is_a?(Float)
      if secs.is_a?(Float)
        s, d = fractional(secs, 0, 1)
        secs = s if d.zero?
      end
      result = []
      result << "#{years}Y"  if years
      result << "#{months}M" if months
      result << "#{weeks}W"  if weeks
      result << "#{days}D"   if days
      result << 'T'          if hours || mins || secs
      result << "#{hours}H"  if hours
      result << "#{mins}M"   if mins
      result << "#{secs}S"   if secs
      result << '0D'         if result.blank?
      ['P', *result].join
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    EPSILON = 0.001

    # fractional
    #
    # @param [Float]               value1
    # @param [Float, Integer, nil] value2
    # @param [Integer]             multiplier
    #
    # @return [(Float, *)]
    #
    def fractional(value1, value2, multiplier)
      value1, fraction = value1.divmod(1)
      if ((ceil = fraction.ceil) - fraction).abs < EPSILON
        fraction = ceil.to_i
      elsif ((floor = fraction.floor) - fraction).abs < EPSILON
        fraction = floor.to_i
      end
      value2 = (value2 || 0) + (fraction * multiplier) if fraction.positive?
      return value1, value2
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

end

# ISO 8601 general date.
#
# @see http://xml.coverpages.org/ISO-FDIS-8601.pdf
#
class IsoDate < ScalarType

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

    # Valid values for this type start with one of these patterns.
    #
    # @type [Hash{Symbol=>Regexp}]
    #
    START_PATTERN = {
      complete: /^(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(Z|[+-]\d\d?(:\d\d)?)?)/,
      day:      /^(\d{4}-\d\d-\d\d)/,
      year:     /^(\d{4})/,
    }.deep_freeze

    # Valid values for this type match one of these patterns.
    #
    # @type [Hash{Symbol=>Regexp}]
    #
    MATCH_PATTERN =
      START_PATTERN.transform_values { |pattern|
        Regexp.new(pattern.source + '$')
      }.deep_freeze

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [*] v
    #
    def valid?(v)
      normalize(v).present?
    end

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    protected

    # Transform *v* into a valid form.
    #
    # @param [String, IsoDate, IsoDay, IsoYear, DateTime, Date, Time, *] v
    #
    # @return [String]
    #
    def normalize(v)
      case v
        when Float                    then "#{v.to_i}-01-01"
        when Integer                  then "#{v}-01-01"
        when IsoYear                  then "#{v}-01-01"
        when IsoDay                   then v.to_s
        when IsoDate                  then v.to_s
        when START_PATTERN[:complete] then $1
        when START_PATTERN[:day]      then $1
        when START_PATTERN[:year]     then "#{$1}-01-01"
        else                               v.to_datetime.strftime rescue ''
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether *v* represents a year value.
    #
    # @param [*] v
    #
    def year?(v)
      normalize(v).match?(MATCH_PATTERN[:year])
    end

    # Indicate whether *v* represents a day value.
    #
    # @param [*] v
    #
    def day?(v)
      normalize(v).match?(MATCH_PATTERN[:day])
    end

    # Indicate whether *v* represents a full ISO 8601 date value.
    #
    # @param [*] v
    #
    def complete?(v)
      normalize(v).match?(MATCH_PATTERN[:complete])
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Type-cast an object to an instance of this type.
    #
    # @param [*] v
    #
    # @return [self, nil]
    #
    def cast(v)
      if v.is_a?(self.class)
        v
      elsif v.present?
        create(v)
      end
    end

    # Create a new instance of this type.
    #
    # @param [*] v
    #
    # @return [self, nil]
    #
    def create(v, *)
      if v.is_a?(self.class)
        v.dup
      elsif (v = normalize(v)).present?
        new(v)
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
  # :section: IsoDate::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance represents a year value, or indicate whether
  # *v* represents a year value.
  #
  # @param [*] v
  #
  def year?(v = nil)
    super(v || @value)
  end

  # Indicate whether the instance represents a day value, or indicate whether
  # *v* represents a day value.
  #
  # @param [*] v
  #
  def day?(v = nil)
    super(v || @value)
  end

  # Indicate whether the instance represents a full ISO 8601 date value, or
  # indicate whether *v* represents a full ISO 8601 date value.
  #
  # @param [*] v
  #
  def complete?(v = nil)
    super(v || @value)
  end

end

# ISO 8601 year.
#
class IsoYear < IsoDate

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include IsoDate::Methods

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [*] v
    #
    def valid?(v)
      year?(v)
    end

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    protected

    # Transform *v* into a valid form.
    #
    # @param [String, IsoDate, IsoDay, IsoYear, DateTime, Date, Time, *] v
    #
    # @return [String]
    #
    def normalize(v)
      case v
        when Float                    then return v.to_i.to_s
        when Integer                  then return v.to_s
        when IsoYear                  then return v.to_s
        when IsoDay                   then v = v.to_s
        when IsoDate                  then v = v.to_s
        when START_PATTERN[:complete] then # continue
        when START_PATTERN[:day]      then # continue
        when START_PATTERN[:year]     then # continue
        else                               v = v.to_date.strftime rescue ''
      end
      v.match(START_PATTERN[:year]) && $1 || ''
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

end

# ISO 8601 day.
#
class IsoDay < IsoDate

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include IsoDate::Methods

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [*] v
    #
    def valid?(v)
      day?(v)
    end

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    protected

    # Transform *v* into a valid form.
    #
    # @param [String, Date, Time, IsoDate, *] v
    #
    # @return [String]
    #
    def normalize(v)
      case v
        when Float                    then return "#{v.to_i}-01-01"
        when Integer                  then return "#{v}-01-01"
        when IsoYear                  then return "#{v}-01-01"
        when IsoDay                   then return v.to_s
        when IsoDate                  then v = v.to_s
        when START_PATTERN[:complete] then # continue
        when START_PATTERN[:day]      then return $1
        when START_PATTERN[:year]     then return "#{$1}-01-01"
        else                               v = v.to_date.strftime rescue ''
      end
      v.match(START_PATTERN[:day]) && $1 || ''
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

end

# ISO 639-2 alpha-3 language code.
#
class IsoLanguage < ScalarType

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include ScalarType::Methods

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    public

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [*] v
    #
    def valid?(v)
      v = normalize(v)
      ISO_639.find_by_code(v).present?
    end

    # =========================================================================
    # :section: ScalarType overrides
    # =========================================================================

    protected

    # Transform *v* into a valid form.
    #
    # @param [String, IsoDate, IsoDay, IsoYear, DateTime, Date, Time, *] v
    #
    # @return [String]
    #
    def normalize(v)
      find(v)&.alpha3 || super(v)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Find a matching language entry.
    #
    # @param [String] value
    #
    # @return [ISO_639, nil]
    #
    def find(value)
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

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  include Methods

end

# Base class for enumeration scalar types.
#
class EnumType < ScalarType

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Enumerations

    # Called from API record definitions to provide this base class with the
    # values that will be accessed implicitly from subclasses.
    #
    # @param [Hash{Symbol=>Hash}] new_entries
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def add_enumerations(new_entries)
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
    def enumerations
      # noinspection RubyClassVariableUsageInspection
      @@enumerations ||= {}
    end

    # The values for an enumeration.
    #
    # @param [Symbol, String] entry
    #
    # @return [Array<String>]
    #
    def values_for(entry)
      enumerations.dig(entry.to_sym, :values)
    end

    # The value/label pairs for an enumeration.
    #
    # @param [Symbol, String] entry
    #
    # @return [Hash]
    #
    def pairs_for(entry)
      enumerations.dig(entry.to_sym, :pairs)
    end

    # The default for an enumeration.
    #
    # @param [Symbol, String] entry
    #
    # @return [String]
    #
    def default_for(entry)
      enumerations.dig(entry.to_sym, :default)
    end

  end

  extend Enumerations

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include ScalarType::Methods

    # =========================================================================
    # :section: ScalarType::Methods overrides
    # =========================================================================

    public

    # The default value associated with this enumeration type.  If no default
    # is explicitly defined the initial value is returned.
    #
    # @return [String]
    #
    def default
      entry = enumerations[type]
      entry[:default] || entry[:values]&.first
    end

    # Indicate whether *v* would be a valid value for an item of this type.
    #
    # @param [*] v
    #
    def valid?(v)
      v = normalize(v)
      values.include?(v)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The name of the represented enumeration type.
    #
    # @return [Symbol]
    #
    def type
      (self.is_a?(Class) ? self : self.class).to_s.to_sym
    end

    # The enumeration values associated with the subclass.
    #
    # @return [Array<String>]
    #
    def values
      enumerations.dig(type, :values)
    end

    # The value/label pairs associated with the subclass.
    #
    # @return [Hash]
    #
    def pairs
      enumerations.dig(type, :pairs)
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
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Assign a new value to the instance.
  #
  # @param [*] v
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
  # @see file:config/locales/en.yml *en.emma.application.deployment*
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

  # Member repository configurations.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  REPOSITORY_CONFIG = I18n.t('emma.repository', default: {}).deep_freeze

  # The default repository for uploads.
  #
  # @type [String]
  #
  # @see file:config/locales/repository.en.yml *en.emma.repository._default*
  #
  DEFAULT_REPOSITORY = REPOSITORY_CONFIG[:_default]

  # Values associated with each source repository.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/repository.en.yml *en.emma.repository*
  # @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/EmmaRepository  JSON schema specification
  #
  REPOSITORY =
    REPOSITORY_CONFIG.reject { |k, _| k.start_with?('_') }.deep_freeze

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
  # @see file:config/locales/types.en.yml *en.emma.categories*
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

  # Language configuration.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  LANGUAGE_CONFIG = I18n.t('emma.language', default: {}).deep_freeze

  # All language codes and labels.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see file:config/locales/types.en.yml *en.emma.language.list*
  #
  LANGUAGE = LANGUAGE_CONFIG[:list] || {}.freeze

  # Languages that appear first in the list.
  #
  # @type [Array<Symbol>]
  #
  # @see file:config/locales/types.en.yml *en.emma.language.primary*
  #
  PRIMARY_LANGUAGES = (LANGUAGE_CONFIG[:primary]&.map(&:to_sym) || []).freeze

  # Language codes and labels in preferred order.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #PRIMARY_LANGUAGES
  # @see #LANGUAGE
  #
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

# Establish the Api::Shared namespace.
#
module Api::Shared
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
