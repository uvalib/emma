# app/types/iso_duration.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

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

    # Indicate whether `*v*` would be a valid value for an item of this type.
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
    # @return [Array(Float, any)]
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

__loading_end(__FILE__)
