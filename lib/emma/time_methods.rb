# lib/emma/time_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Time and time span methods.
#
module Emma::TimeMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  MICROSECONDS_PER_SECOND = 1000000.0
  MILLISECONDS_PER_SECOND = 1000.0

  SECONDS_PER_MICROSECOND = 1.0 / MICROSECONDS_PER_SECOND
  SECONDS_PER_MILLISECOND = 1.0 / MILLISECONDS_PER_SECOND
  SECONDS_PER_SECOND      = 1.0
  SECONDS_PER_MINUTE      = 60.0
  SECONDS_PER_HOUR        = 60.0 * SECONDS_PER_MINUTE

  MINUTES_PER_SECOND      = 1.0 / SECONDS_PER_MINUTE
  HOURS_PER_SECOND        = 1.0 / SECONDS_PER_HOUR

  MICROSECOND  = SECONDS_PER_MICROSECOND
  MILLISECOND  = SECONDS_PER_MILLISECOND
  SECOND       = SECONDS_PER_SECOND
  MINUTE       = SECONDS_PER_MINUTE
  HOUR         = SECONDS_PER_HOUR

  MICROSECONDS = MICROSECONDS_PER_SECOND
  MILLISECONDS = MILLISECONDS_PER_SECOND
  SECONDS      = SECONDS_PER_SECOND
  MINUTES      = MINUTES_PER_SECOND
  HOURS        = HOURS_PER_SECOND

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The current time in seconds.
  #
  # @param [Symbol, nil] unit
  #
  # @return [Float]
  #
  # @see Process#clock_gettime
  #
  def timestamp(unit = :float_second)
    # noinspection RubyMismatchedArgumentType
    Process.clock_gettime(Process::CLOCK_MONOTONIC, unit)
  end

  # A time span message.
  #
  # @param [Float]     start_time
  # @param [Float,nil] end_time       Default: the current timestamp.
  #
  # @return [String]
  #
  # @see #timestamp
  #
  def time_span(start_time, end_time = nil)
    end_time ||= timestamp
    start_time = end_time unless start_time.is_a?(Numeric)
    # noinspection RubyMismatchedArgumentType
    delta = end_time - start_time
    time  = delta.abs
    sign  = ('-' unless time == delta)
    if    time < MILLISECOND; scale = MICROSECONDS; units = 'μsec'
    elsif time < SECOND;      scale = MILLISECONDS; units = 'msec'
    elsif time < MINUTE;      scale = SECONDS;      units = 'sec'
    elsif time < HOUR;        scale = MINUTES;      units = 'min'
    else                      scale = HOURS;        units = 'hr'
    end
    "#{sign}%.1f #{units}" % (time * scale)
  end

end

__loading_end(__FILE__)
