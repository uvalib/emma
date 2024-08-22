# app/types/iso_date.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

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

__loading_end(__FILE__)
