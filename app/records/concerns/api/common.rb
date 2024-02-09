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
  include Emma::Common
  include Emma::Constants
  include Emma::TypeMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include Emma::Common
    include Emma::Constants

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
    # @param [any, nil] v
    #
    def valid?(v)
      !v.nil?
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      v = clean(v)
      v.is_a?(String) ? v.strip : v.to_s
    end

    # Resolve an item into its value.
    #
    # @param [any, nil] v
    #
    # @return [any, nil]
    #
    def clean(v)
      v = v.value if v.is_a?(Field::Type)
      v = v.value if v.is_a?(ScalarType) && !v.is_a?(self_class)
      v = nil     if v == EMPTY_VALUE
      v.is_a?(Array) ? v.excluding(nil, EMPTY_VALUE) : v
    end

    # Type-cast an object to an instance of this type.
    #
    # @param [any, nil] v             Value to use or transform.
    # @param [Hash]     opt           Options passed to #create.
    #
    # @return [superclass, nil]
    #
    def cast(v, **opt)
      c = self_class
      v.is_a?(c) ? v : create(v, **opt)
    end

    # Create a new instance of this type.
    #
    # @param [any, nil] v             Value to use or transform.
    # @param [Hash]     opt           Options passed to #initialize.
    #
    # @return [superclass, nil]
    #
    def create(v, **opt)
      c = self_class
      if v.is_a?(c)
        v.dup
      elsif (v = normalize(v)).present?
        c.new(v, **opt)
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
  # @param [any, nil] v               Optional initial value.
  # @param [Hash]     opt             Options passed to #set.
  #
  def initialize(v = nil, **opt)
    set(v, **opt)
  end

  # Assign a new value to the instance.
  #
  # @param [any, nil] v
  #
  # @return [String, nil]
  #
  def value=(v)
    set(v)
  end

  # Assign a new value to the instance.
  #
  # @param [any, nil] v
  # @param [Boolean]  invalid         If *true* allow invalid value.
  # @param [Boolean]  allow_nil       If *false* use #default if necessary.
  # @param [Boolean]  warn            If *true* log invalid.
  #
  # @return [String, nil]
  #
  def set(v, invalid: false, allow_nil: true, warn: false, **)
    v = nil if v == EMPTY_VALUE
    unless v.nil?
      @value = normalize(v)
      @value = nil unless valid?(@value)
      Log.warn { "#{type}: #{v.inspect}: not in #{values}" } if warn && !@value
    end
    @value ||= (v if invalid) || (default unless allow_nil)
  end

  # ===========================================================================
  # :section: ScalarType::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid, or indicate whether *v* would be a
  # valid value.
  #
  # @param [any, nil] v
  #
  def valid?(v = nil)
    v ||= value
    super
  end

  # Transform value into a valid form.
  #
  # @param [any, nil] v
  #
  # @return [String]
  #
  def normalize(v = nil)
    v ||= value
    super
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
    value.to_s
  end

  # Return the inspection of the instance value.
  #
  # @return [String]
  #
  def inspect
    "#{self.class}(#{to_s.inspect})"
  end

  # Indicate whether the instance has a blank value.
  #
  def blank?
    value.blank?
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
  # @param [any, nil] other
  #
  def eql?(other)
    to_s == other.to_s
  end

  # Return the value as represented within JSON.
  #
  # @return [String]
  #
  def to_json
    to_s.to_json
  end

  # Return the value as represented within JSON.
  #
  # @return [String]
  #
  def as_json
    to_s.as_json
  end

  # ===========================================================================
  # :section: Comparable
  # ===========================================================================

  public

  # Comparison operator required by the Comparable mixin.
  #
  # @param [any, nil] other
  #
  # @return [Integer]   -1 if self is later, 1 if self is earlier
  #
  def <=>(other)
    to_s <=> other.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The natural language presentation for the current enumeration value.
  #
  # @return [String]
  #
  def label
    to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a serializer class associated with the given *base*.
  #
  # @param [Class] base
  #
  # @return [void]
  #
  def self.define_serializer(base = self)
    base.class_exec do

      include Serializable

      serializer :serialize do |item|
        item.value
      end

    end
  end

  # Create a serializer class associated with the given *base* and arrange for
  # any subclasses to have their own serializers.
  #
  # @param [Class] base
  #
  # @return [void]
  #
  def self.generate_serializer(base = self)
    define_serializer(base)
    base.class_exec do
      def self.inherited(subclass)
        generate_serializer(subclass)
      end
    end
  end

  generate_serializer

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
    # @param [any, nil] v
    #
    def valid?(v)
      normalize(v).present?
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v             String, Date, Time, IsoDate
    #
    # @return [String]
    #
    def normalize(v)
      v = clean(v)
      v = nil if v.is_a?(String) && !MATCH_PATTERN.any? { |_, p| v.match?(p) }
      # noinspection RubyMismatchedArgumentType
      v.is_a?(ActiveSupport::Duration) ? from_duration(v) : v.to_s
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
    # @return [Array<(Float, any)>]
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
      base.extend(self)
    end

  end

  include Methods

  # ===========================================================================
  # :section: IsoDuration::Methods overrides
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
    # @param [any, nil] v
    #
    def valid?(v)
      normalize(v).present?
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v   String,IsoDate,IsoDay,IsoYear,DateTime,Date,Time
    #
    # @return [String, nil]
    #
    def normalize(v)
      v = clean(v)
      return v.value         if v.is_a?(self_class)
      v = strip_copyright(v) if v.is_a?(String)
      datetime_convert(v)
    end

    # Type-cast an object to an instance of this type.
    #
    # @param [any, nil] v             Value to use or transform.
    # @param [Hash]     opt           Options passed to #create.
    #
    # @return [IsoDate, nil]
    #
    def cast(v, **opt)
      c = self_class
      v.is_a?(c) ? v : create(v, **opt)
    end

    # Create a new instance of this type.
    #
    # @param [any, nil] v
    # @param [Hash]     opt           Options passed to #initialize.
    #
    # @return [IsoDate, nil]
    #
    def create(v, **opt)
      c = self_class
      if v.is_a?(c)
        v.dup
      elsif (v = normalize(v)).present?
        c.new(v, **opt)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Prepare a date string for normalization.
    #
    # @param [any, nil] v   String,IsoDate,IsoDay,IsoYear,DateTime,Date,Time
    #
    # @return [any, nil]
    #
    def strip_copyright(v)
      return v unless v.is_a?(String)
      v.sub(/^[cC]\.?/, '').gsub(/[(\[][cC©]\.?[)\]]|©/, '')
    end

    # Transform *v* into a ISO 8601 form.
    #
    # @param [any, nil] v   String,IsoDate,IsoDay,IsoYear,DateTime,Date,Time
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
    # @param [any, nil] v   String,IsoDate,IsoDay,IsoYear,DateTime,Date,Time
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
    # @param [any, nil] v   String,IsoDate,IsoDay,IsoYear,DateTime,Date,Time
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
    # @param [any, nil] value         String, Date, Time, IsoDate
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
    # @param [any, nil] value         String, Date, Time, IsoDate
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
    # @param [any, nil] value         String, Date, Time, IsoDate
    #
    # @return [String, Date, Time, IsoDate, any, nil]
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
    # === Implementation Notes
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
    # @param [any, nil] value         String
    #
    # @return [String]
    #
    # @see http://www.verypdf.com/pdfinfoeditor/pdf-date-format.htm
    #
    def pdf_date_translate(value)
      # Strip optional date tag.  If the remainder is just four digits, pass it
      # back as a year value in a form that Date#parse will accept.  If the
      # remainder doesn't have at least five digits then assume this is not an
      # ASN.1 style date and that, hopefully, Date#parse can handle it.
      value = value.to_s.strip.upcase.delete_prefix('D:')
      return "#{$1}/01" if value.match(/^(#{YEAR})$/)
      return value      unless value.match(/^\d{5}/)

      # Strip the optional timezone from the end so that *tz* is either *nil*,
      # 'Z', "-hh:mm" or "+hh:mm".  (The single quotes are supposed to be
      # required, but this will attempt to handle variations that aren't too
      # off-the-wall.)
      tz = nil
      value.sub!(ASN_1_TIMEZONE) do |match|
        tz = (match == ZULU) ? match : $1 + [$2, $4].compact_blank!.join(':')
        '' # Remove the matched substring from *value*.
      end

      # Get optional date and time parts.  Because Date#parse won't accept
      # something like "2021-12" but will correctly interpret "2021/12" as
      # "December 2021", '/' is used as the date separator.
      result = []
      # noinspection RubyResolve
      value.sub!(ASN_1_DATETIME) do
        result << [$1, $3, $5 ].compact_blank!.join('/') # Date parts
        result << [$7, $9, $10].compact_blank!.join(':') # Time parts
        result << tz                                     # Time zone
      end
      result.compact_blank!.join(' ')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether *v* represents a year value.
    #
    # @param [any, nil] v
    #
    def year?(v)
      normalize(v).to_s.match?(MATCH_PATTERN[:year])
    end

    # Indicate whether *v* represents a day value.
    #
    # @param [any, nil] v
    #
    def day?(v)
      normalize(v).to_s.match?(MATCH_PATTERN[:day])
    end

    # Indicate whether *v* represents a full ISO 8601 date value.
    #
    # @param [any, nil] v
    #
    def complete?(v)
      normalize(v).to_s.match?(MATCH_PATTERN[:complete])
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
  # :section: IsoDate::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid.
  #
  # @param [String, any, nil] v       Default: #value.
  #
  def valid?(v = nil)
    v ||= value
    super
  end

  # Indicate whether the instance represents a year value, or indicate whether
  # *v* represents a year value.
  #
  # @param [any, nil] v
  #
  def year?(v = nil)
    v ||= value
    super
  end

  # Indicate whether the instance represents a day value, or indicate whether
  # *v* represents a day value.
  #
  # @param [any, nil] v
  #
  def day?(v = nil)
    v ||= value
    super
  end

  # Indicate whether the instance represents a full ISO 8601 date value, or
  # indicate whether *v* represents a full ISO 8601 date value.
  #
  # @param [any, nil] v
  #
  def complete?(v = nil)
    v ||= value
    super
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
    # @param [any, nil] v
    #
    def valid?(v)
      year?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String, nil]
    #
    def normalize(v)
      v = clean(v)
      return v.value         if v.is_a?(self_class)
      v = strip_copyright(v) if v.is_a?(String)
      year_convert(v)
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
  # :section: IsoYear::Methods overrides
  # ===========================================================================

  public

  # Indicate whether the instance is valid.
  #
  # @param [String, nil] v            Default: #value.
  #
  def valid?(v = nil)
    v ||= value
    super
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
    # @param [any, nil] v
    #
    def valid?(v)
      day?(v)
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v             String, Date, Time, IsoDate
    #
    # @return [String, nil]
    #
    def normalize(v)
      v = clean(v)
      return v.value         if v.is_a?(self_class)
      v = strip_copyright(v) if v.is_a?(String)
      day_convert(v)
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
  # :section: IsoDay::Methods overrides
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

# ISO 639-2 alpha-3 language code.
#
# TODO: This should be eliminated in favor of LanguageType.
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
    # @param [any, nil] v             String
    #
    def valid?(v)
      v = normalize(v)
      ISO_639.find_by_code(v).present?
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v             String
    #
    # @return [String]
    #
    def normalize(v)
      v = super
      code(v) || v
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Return the associated three-letter language code.
    #
    # @param [any, nil] value         String
    #
    # @return [String, nil]
    #
    def code(value)
      find(value)&.alpha3
    end

    # Find a matching language entry.
    #
    # @param [any, nil] value         String
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
      base.extend(self)
    end

  end

  include Methods

  # ===========================================================================
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Assign a new value to the instance.
  #
  # @param [any, nil] v
  # @param [Hash]     opt             Passed to ScalarType#set
  #
  # @return [String, nil]
  #
  def set(v, **opt)
    opt.reverse_merge!(warn: true)
    super
  end

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

end

# Base class for enumeration scalar types.
#
class EnumType < ScalarType

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Comparable

    # Transform a value into a string for liberal case-insensitive comparison
    # where non-alphanumeric are disregarded.
    #
    # @param [String, Symbol, nil] key
    #
    # @return [String]
    #
    def comparable(key)
      key.to_s.downcase.remove!(/[_\W]/)
    end

    # Create a mapping of comparable values to original values.
    #
    # @param [Array, Hash]         keys
    # @param [String, Symbol, nil] caller   For diagnostics.
    #
    # @return [Hash{String=>String,Symbol}]
    #
    def comparable_map(keys, caller = nil)
      keys = keys.keys if keys.is_a?(Hash)
      keys.map { |k| [comparable(k), k] }.to_h.tap do |result|
        unless (rs = result.size) == (ks = keys.size)
          # This is a "can't happen" situation where two original values
          # transform to the same comparable value.
          caller ||= __method__
          Log.error { "#{caller}: #{rs} map keys != #{ks} original keys" }
          Log.info  { "#{caller}: map keys: #{result.keys.inspect}" }
          Log.info  { "#{caller}: original: #{keys.inspect}" }
        end
      end
    end

  end

  extend Comparable

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Enumerations

    include Comparable

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Add enumeration values from configuration entries.
    #
    # @param [String, Hash]        arg
    # @param [Symbol, String, nil] name
    #
    # @return [Hash{Symbol=>Hash}]
    #
    #--
    # === Variations
    #++
    #
    # @overload add_enumeration(i18n_path, name)
    #   A configuration entry where the last part of the path is a string that
    #   when camelized is the same as the name of the class being defined.
    #   (E.g. "emma.manifest_item.type.file_path" for class FilePath.)
    #   @param [String]              i18n_path
    #   @return [Hash{Symbol=>Hash}]
    #
    # @overload add_enumeration(i18n_path, name)
    #   A configuration entry where the last part of the path is a string that
    #   @param [String]              i18n_path
    #   @param [Symbol, String]      name
    #   @return [Hash{Symbol=>Hash}]
    #
    # @overload add_enumeration(i18n_path, name)
    #   @param [Hash]                config
    #   @param [Symbol, String, nil] name
    #   @return [Hash{Symbol=>Hash}]
    #
    def add_enumeration(arg, name = nil)
      key = name.presence
      key = key.underscore if key.is_a?(String)
      case arg
        when String
          part  = arg.split('.')
          name  = part.last       if name.blank?
          arg   = "#{arg}.#{key}" if key && (key != part.last)
          entry = get_configuration(arg.to_s)
        when Hash
          raise 'name required for Hash argument' if name.blank?
          key   = key&.to_sym
          entry = arg[key] || arg
        else
          raise "invalid type #{arg.class}"
      end
      add_enumerations(name => entry)
    end

    # add_enumerations_from
    #
    # @param [String] i18n_path
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def add_enumerations_from(i18n_path)
      config = get_configuration(i18n_path)
      raise "'#{i18n_path}' is not a Hash" unless config.is_a?(Hash)
      add_enumerations(config)
    end

    # Called from API record definitions to provide this base class with the
    # values that will be accessed implicitly from subclasses.
    #
    # @param [Hash{Symbol,String=>any,nil}] entries
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def add_enumerations(entries)
      entries =
        entries.map { |name, cfg|
          if cfg.is_a?(Hash)
            default = cfg[:_default].presence
            pairs   = cfg.except(:_default).stringify_keys
            values  = pairs.keys
          else
            default = nil
            values  = Array.wrap(cfg).map(&:to_s)
            pairs   = values.map { |v| [v, v] }.to_h
          end
          name  = name.to_s.camelize.to_sym
          map   = comparable_map(values, "Enumeration #{name}")
          entry = { values: values, pairs: pairs, mapping: map }
          entry.merge!(default: default) unless default.nil?
          [name, entry]
        }.to_h
      enumerations.merge!(entries)
    end

    # Enumeration definitions accumulated from API records.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    # === Implementation Notes
    # This needs to be a class variable so that all subclasses reference the
    # same set of values.
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

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # get_configuration
    #
    # @param [String]                   i18n_path
    # @param [Array<Symbol>,Symbol,nil] default
    #
    # @return [Hash, Array<String>, nil]
    #
    def get_configuration(i18n_path, default: nil)
      config_item(i18n_path, default: default).tap do |config|
        raise "'#{i18n_path}' is empty" if config.blank?
        if config.is_a?(Hash)
          items = config.reject { |k, _| k.start_with?('_') }
          raise "'#{i18n_path}' has no items" if items.blank?
        elsif !config.is_a?(Array)
          raise "'#{i18n_path}' is not a Hash or Array"
        end
      end
    end

  end

  extend Enumerations

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    include ScalarType::Methods
    include Comparable
    extend Enumerations

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
    # @param [any, nil] v
    #
    def valid?(v)
      values.include?(normalize(v))
    end

    # Transform *v* into a valid form.
    #
    # @param [any, nil] v
    #
    # @return [String]
    #
    def normalize(v)
      v = clean(v)
      return v.value if v.is_a?(self_class)
      (v = super).presence && mapping[comparable(v)] || v
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
      self_class.to_s.to_sym
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
    # @see ApplicationRecord#pairs
    #
    def pairs(**)
      enumerations.dig(type, :pairs)
    end

    # Mapping of comparable values to enumeration values.
    #
    # @return [Hash]
    #
    def mapping
      enumerations.dig(type, :mapping)
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
  # :section: ScalarType overrides
  # ===========================================================================

  public

  # Assign a new value to the instance.
  #
  # @param [any, nil]    v
  # @param [Hash] opt                 Passed to ScalarType#set
  #
  # @return [String, nil]
  #
  def set(v, **opt)
    opt.reverse_merge!(warn: true)
    super
  end

  # ===========================================================================
  # :section: EnumType::Methods overrides
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The natural language presentation for the current enumeration value.
  #
  # @return [String]
  #
  def label
    pairs[value] || super
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # This is a convenience for defining a subclass of EnumType in terms of the
  # configuration which holds its enumeration values (and their related natural
  # language labels).
  #
  # @param [String, Hash]        arg
  # @param [Symbol, String, nil] name
  #
  # @return [Class]
  #
  # @see #add_enumeration
  #
  def self.[](arg, name = nil)
    add_enumeration(arg, name)
    self
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.inherited(subclass)
    subclass.delegate :enumerations, to: :EnumType
    Object.define_method(subclass.to_s.to_sym) do |v, **opt|
      subclass.cast(v, **opt)
    end
  end

end

# =============================================================================
# Module definition
# =============================================================================

public

# Shared values and methods.
#
module Api::Common

  include Emma::Constants

  # ===========================================================================
  # Common configuration values - Authentication Providers
  # ===========================================================================

  public

  # Table of authentication provider names.
  #
  # @type [Hash{Symbol=>String}]
  #
  AUTH_PROVIDER_MAP =
    AUTH_PROVIDERS.map { |auth| [auth, auth.to_s.titleize] }.to_h.deep_freeze

  # ===========================================================================
  # Common configuration values - Deployments
  # ===========================================================================

  public

  # Values associated with each deployment type.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/en.yml
  #
  DEPLOYMENT = config_section('emma.application.deployment').deep_freeze

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

  # Partner repository configurations.
  #
  # @type [Hash{Symbol=>any}]
  #
  REPOSITORY_CONFIG = config_section('emma.repository').deep_freeze

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
  # Common configuration values - LanguageType
  # ===========================================================================

  public

  # Language configuration.
  #
  # @type [Hash{Symbol=>any}]
  #
  LANGUAGE_CONFIG = config_section('emma.language').deep_freeze

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
  # Common configuration values - MemberStatus
  # ===========================================================================

  public

  # Membership status of an EMMA user or EMMA member organization.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/types/account.en.yml
  #
  MEMBER_STATUS = config_section('emma.account.type.MemberStatus').deep_freeze

  # Table of membership status.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #MEMBER_STATUS
  #
  MEMBER_STATUS_MAP =
    MEMBER_STATUS.transform_values { |config| config[:label] }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  EnumType.add_enumerations(AuthProvider:   AUTH_PROVIDER_MAP)
  EnumType.add_enumerations(Deployment:     DEPLOYMENT_MAP)
  EnumType.add_enumerations(EmmaRepository: REPOSITORY_MAP)
  EnumType.add_enumerations(LanguageType:   LANGUAGE_MAP)
  EnumType.add_enumerations(MemberStatus:   MEMBER_STATUS_MAP)

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

# @see Api::Common#AUTH_PROVIDER_MAP
class AuthProvider < EnumType; end

# @see Api::Common#DEPLOYMENT_MAP
class Deployment < EnumType; end

# @see Api::Common#REPOSITORY_MAP
class EmmaRepository < EnumType; end

# @see Api::Common#MEMBER_STATUS_MAP
class MemberStatus < EnumType; end

# @see Api::Common#LANGUAGE_MAP
class LanguageType < EnumType

  include IsoLanguage::Methods

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

end

__loading_end(__FILE__)
