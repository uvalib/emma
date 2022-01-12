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

  include Comparable

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
    # @param [Any, nil] v
    #
    def valid?(v)
      !v.nil?
    end

    # Transform *v* into a valid form.
    #
    # @param [Any, nil] v
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
  # @param [Any, nil] v               Optional initial value.
  #
  def initialize(v = nil, *)
    set(v)
  end

  # Assign a new value to the instance.
  #
  # @param [Any, nil] v
  #
  # @return [String]
  #
  def value=(v)
    set(v)
  end

  # Assign a new value to the instance.
  #
  # @param [Any, nil] v
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
  # @param [Any, nil] v
  #
  def valid?(v = nil)
    super(v || @value)
  end

  # Transform value into a valid form.
  #
  # @param [Any, nil] v
  #
  # @return [String]
  #
  def normalize(v = nil)
    super(v || @value)
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

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

  # Value needed to make instances comparable.
  #
  # @return [Integer]
  #
  def hash
    to_s.hash
  end

  # Value needed to make instances comparable.
  #
  # @param [Any] other
  #
  def eql?(other)
    to_s == other.to_s
  end

  # ===========================================================================
  # :section: Comparable
  # ===========================================================================

  public

  # Comparison operator required by the Comparable mixin.
  #
  # @param [Any] other
  #
  # @return [Integer]   -1 if self is later, 1 if self is earlier
  #
  def <=>(other)
    to_s <=> other.to_s
  end

  # ===========================================================================
  # :section: Object class overrides
  # ===========================================================================

  public

  # By default, Object#deep_dup will create a copy of an item, including values
  # which are classes themselves, if the item says that it is duplicable.
  #
  # For items which are classes, e.g.:
  #
  #   { item: ScalarType }
  #
  # this would mean that the duplicated result would be something like:
  #
  #   { item: #<Class:0x00005590b0d928a8> }
  #
  # Returning *false* here prevents that.
  #
  def self.duplicable?
    false
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
    # @param [Any, nil] v
    #
    def valid?(v)
      normalize(v).present?
    end

    # Transform *v* into a valid form.
    #
    # @param [String, Date, Time, IsoDate, Any, nil] v
    #
    # @return [String]
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def normalize(v)
      case v
        when ActiveSupport::Duration then return from_duration(v)
        when IsoDuration             then return v.to_s
        else                              v = v.to_s
      end
      # noinspection RubyNilAnalysis, RubyMismatchedReturnType
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

    # @private
    EPSILON = 0.001

    # fractional
    #
    # @param [Float]               value1
    # @param [Float, Integer, nil] value2
    # @param [Integer]             multiplier
    #
    # @return [Array<(Float, Any)>]
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

  # ===========================================================================
  # :section: IsoDuration::Methods overrides
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

    YEAR     = '\d{4}'
    MONTH    = '\d\d'
    DAY      = '\d\d'
    DATE     = "(#{YEAR})-(#{MONTH})-(#{DAY})"

    HOUR     = '\d\d'
    MINUTE   = '\d\d'
    SECOND   = '\d\d'
    FRACTION = '\.\d+'
    TIME     = "(#{HOUR}):(#{MINUTE})(:(#{SECOND})(#{FRACTION})?)?"

    ZULU     = 'Z'
    H_OFFSET = '\d\d?'
    M_OFFSET = '\d\d?'
    ZONE     = "#{ZULU}|([+-])(#{H_OFFSET})(:(#{M_OFFSET}))?"

    # Valid values for this type start with one of these patterns.
    #
    # @type [Hash{Symbol=>Regexp}]
    #
    START_PATTERN = {
      complete: /^\s*(#{DATE}[T|\s+]#{TIME}\s*(#{ZONE})?)/,
      day:      /^\s*(#{DATE})\s*/,
      year:     /^\s*(#{YEAR})\s*/,
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
    # @param [Any] v
    #
    def valid?(v)
      normalize(v).present?
    end

    # Transform *v* into a valid form.
    #
    # @param [String, IsoDate, IsoDay, IsoYear, DateTime, Date, Time, Any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      (datetime_convert(v) || v).to_s
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Transform *v* into a ISO 8601 form.
    #
    # @param [String, IsoDate, IsoDay, IsoYear, DateTime, Date, Time, Any, nil] v
    #
    # @return [String, nil]
    #
    def datetime_convert(v)
      case v
        when nil, 0                   then nil
        when Numeric                  then day_convert(v)
        when IsoYear                  then day_convert(v)
        when IsoDay                   then day_convert(v)
        when IsoDate                  then v.to_s
        when START_PATTERN[:complete] then datetime_clean($1)
        when START_PATTERN[:day]      then $1
        when START_PATTERN[:year]     then day_convert(v)
        else                               datetime_parse(v)
      end
    end

    # Transform *v* into "YYYY-MM-DD" form.
    #
    # @param [String, IsoDate, IsoDay, IsoYear, DateTime, Date, Time, Any, nil] v
    #
    # @return [String, nil]
    #
    def day_convert(v)
      case v
        when nil, 0                   then nil
        when Numeric                  then day_convert(year_convert(v))
        when IsoYear                  then day_convert(v.to_s)
        when IsoDay                   then v.to_s
        when IsoDate                  then day_convert(v.to_s)
        when START_PATTERN[:complete] then "#{$2}-#{$3}-#{$4}"
        when START_PATTERN[:day]      then $1
        when START_PATTERN[:year]     then "#{$1}-01-01"
        else                               day_convert(date_parse(v))
      end
    end

    # Transform *v* into a 4-digit year.
    #
    # @param [String, IsoDate, IsoDay, IsoYear, DateTime, Date, Time, Any, nil] v
    #
    # @return [String, nil]
    #
    def year_convert(v)
      case v
        when nil, 0                   then nil
        when Numeric                  then v.to_i.to_s
        when IsoYear                  then v.to_s
        when IsoDay                   then year_convert(v.to_s)
        when IsoDate                  then year_convert(v.to_s)
        when START_PATTERN[:complete] then $2
        when START_PATTERN[:day]      then $2
        when START_PATTERN[:year]     then $1
        else                               year_convert(date_parse(v))
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Transform a value into ISO 8601 form.
    #
    # @param [String, Date, Time, IsoDate, Any, nil] value
    #
    # @return [String, nil]
    #
    def datetime_parse(value)
      dt = translate(value)&.to_datetime&.strftime
      datetime_clean(dt) if dt
    rescue
      nil
    end

    # Transform a value into "YYYY-MM-DD" form.
    #
    # @param [String, Date, Time, IsoDate, Any, nil] value
    #
    # @return [String, nil]
    #
    def date_parse(value)
      translate(value)&.to_date&.strftime
    rescue
      nil
    end

    # Transform a date string into a usable form.
    #
    # Because DateTime#parse doesn't cope with American date formats, dates of
    # the form "M/D/Y" are converted to "YYYY-MM-DD", however forms like
    # "YYYY/MM/..." are preserved (since DateTime#parse can deal with those).
    #
    # Note that "YYYY/DD/MM" will still be a problem because "DD" will be
    # interpreted as month and "MM" will be interpreted as day.
    #
    # @param [String, Date, Time, IsoDate, Any, nil] value
    #
    # @return [String, Date, Time, IsoDate, Any, nil]
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def translate(value)
      return value unless value.is_a?(String)
      result = pdf_date_translate(value)
      result = american_date_translate(value) if result == value
      result
    end

    # Remove fractional seconds and normalize +00:00 to Z.
    #
    # @param [String, nil] value
    #
    # @return [String]
    #
    # == Implementation Notes
    # Fractional seconds are rounded unless >= 59 seconds.  In that case, the
    # fractional part is truncated in order to avoid a potential cascade of
    # changes to minute, hour, etc.
    #
    def datetime_clean(value)
      value.to_s.strip.sub(/[+-]00?(:00?)?$/, ZULU).sub(/\d+\.\d+/) do |sec|
        '%02d' % [sec.to_f.round, 59].min
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    MM = '\d{1,2}'
    DD = '\d{1,2}'
    YY = '\d{4}|\d{2}'

    AMERICAN_DATE = %r{^\s*(#{MM})([/.-])(#{DD})\2(#{YY})}.freeze

    # Transform an American-style date string into a usable form.
    #
    # Because DateTime#parse doesn't cope with American date formats, dates of
    # the form "M/D/Y" are converted to "YYYY-MM-DD", however forms like
    # "YYYY/MM/..." are preserved (since DateTime#parse can deal with those).
    #
    # Note that "YYYY/DD/MM" will still be a problem because "DD" will be
    # interpreted as month and "MM" will be interpreted as day.
    #
    # @param [String] value
    #
    # @return [String]
    #
    def american_date_translate(value)
      value.to_s.strip.sub(AMERICAN_DATE) do
        mm = $1.to_s
        dd = $3.to_s
        yy = $4.to_s
        yy = '%02d%02d' % [DateTime.now.year.div(100), yy] if yy.size == 2
        '%04d-%02d-%02d' % [yy, mm, dd]
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    OPTIONAL_SECONDS = "(#{SECOND})?"
    OPTIONAL_MINUTES = "((#{MINUTE})#{OPTIONAL_SECONDS})?"
    OPTIONAL_TIME    = "((#{HOUR})#{OPTIONAL_MINUTES})?"
    OPTIONAL_DAY     = "((#{DAY})#{OPTIONAL_TIME})?"
    OPTIONAL_MONTH   = "((#{MONTH})#{OPTIONAL_DAY})?"

    ASN_1_DATETIME =
      /(#{YEAR})#{OPTIONAL_MONTH}/.freeze

    ASN_1_TIMEZONE =
      /#{ZULU}$|([+-])(#{H_OFFSET})[':]?((#{M_OFFSET})[':]?)?$/i.freeze

    # Transform an ISO/IEC 8824 (ASN.1) date string into a usable form.
    #
    # @param [String, Any] value
    #
    # @return [String]
    #
    # @see http://www.verypdf.com/pdfinfoeditor/pdf-date-format.htm
    #
    def pdf_date_translate(value)
      # Strip optional date tag.  If the remainder is just four digits, pass it
      # back as a year value in a form that Date#parse will accept.  If the
      # remainder doesn't have have at least five digits then assume this is
      # not an ASN.1 style date and that, hopefully, Date#parse can handle it.
      value = value.to_s.strip.upcase.delete_prefix('D:')
      return "#{$1}/01" if value.match(/^(#{YEAR})$/)
      return value      unless value.match(/^\d{5}/)

      # Strip the optional timezone from the end so that *tz* is either *nil*,
      # 'Z', "-hh:mm" or "+hh:mm".  (The single quotes are supposed to be
      # required, but this will attempt to handle variations that aren't too
      # off-the-wall.)
      tz = nil
      value.sub!(ASN_1_TIMEZONE) do |match|
        tz = (match == ZULU) ? match : $1 + [$2, $4].compact_blank.join(':')
        '' # Remove the matched substring from *value*.
      end

      # Get optional date and time parts.  Because Date#parse won't accept
      # something like "2021-12" but will correctly interpret "2021/12" as
      # "December 2021", '/' is used as the date separator.
      result = []
      # noinspection RubyResolve, RubyMismatchedArgumentType
      value.sub!(ASN_1_DATETIME) do
        result << [$1, $3, $5 ].compact_blank.join('/') # Date parts
        result << [$7, $9, $10].compact_blank.join(':') # Time parts
        result << tz                                    # Time zone
      end
      result.compact_blank!.join(' ')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether *v* represents a year value.
    #
    # @param [Any] v
    #
    def year?(v)
      normalize(v).match?(MATCH_PATTERN[:year])
    end

    # Indicate whether *v* represents a day value.
    #
    # @param [Any] v
    #
    def day?(v)
      normalize(v).match?(MATCH_PATTERN[:day])
    end

    # Indicate whether *v* represents a full ISO 8601 date value.
    #
    # @param [Any] v
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
    # @param [Any, nil] v
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
    # @param [Any, nil] v
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

  # Indicate whether the instance is valid.
  #
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    super(v || value)
  end

  # Indicate whether the instance represents a year value, or indicate whether
  # *v* represents a year value.
  #
  # @param [Any] v
  #
  def year?(v = nil)
    super(v || @value)
  end

  # Indicate whether the instance represents a day value, or indicate whether
  # *v* represents a day value.
  #
  # @param [Any] v
  #
  def day?(v = nil)
    super(v || @value)
  end

  # Indicate whether the instance represents a full ISO 8601 date value, or
  # indicate whether *v* represents a full ISO 8601 date value.
  #
  # @param [Any] v
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
    # @param [Any] v
    #
    def valid?(v)
      year?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [Any] v
    #
    # @return [String]
    #
    def normalize(v)
      (year_convert(v) || v).to_s
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
  # :section: IsoYear::Methods overrides
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
    # @param [Any] v
    #
    def valid?(v)
      day?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [String, Date, Time, IsoDate, Any] v
    #
    # @return [String]
    #
    def normalize(v)
      (day_convert(v) || v).to_s
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
  # :section: IsoDay::Methods overrides
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
    # @param [String, Any] v
    #
    def valid?(v)
      v = normalize(v)
      ISO_639.find_by_code(v).present?
    end

    # Transform *v* into a valid form.
    #
    # @param [String, Any] v
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
        # @type [ISO_639] entry
        entries.find do |entry|
          (value == entry.alpha3) ||
            entry.english_name.downcase.split(/\s*;\s*/).any? do |part|
              value == part.strip
            end
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

  # ===========================================================================
  # :section: IsoLanguage::Methods overrides
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
    # @param [Any, nil] v
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
  # @param [Any] v
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
  # :section: EnumType::Methods overrides
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
  # @type [Hash{Symbol=>Any}]
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
  # @type [Hash{Symbol=>Any}]
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
