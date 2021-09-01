# app/records/concerns/api/shared/date_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to dates.
#
module Api::Shared::DateMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Normalization array handling.
  #
  # :required   Results always given as arrays.
  # :forbidden  Results are only given a singles.
  # :auto       Results given as arrays when indicated; singles otherwise.
  #
  # @type [Array<Symbol>]
  #
  ARRAY_MODES = %i[auto required forbidden].freeze unless defined?(ARRAY_MODES)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fields that must be transmitted as "YYYY-MM-DD".
  #
  # @return [Array<Symbol>]
  #
  def day_fields
    []
  end

  # Policy for how date multiple date values are handled.
  #
  # (Default is :forbidden because this is what Ingest requires.)
  #
  # @return [Symbol]                  One of #ARRAY_MODES.
  #
  def date_array_mode
    :forbidden
  end

  # The pattern which separates multiple date representations within a String.
  #
  # @return [Regexp]
  #
  def date_separator
    /[|\n]+/
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce day values of the form "YYYY-MM-DD".
  #
  # @param [Hash]   data
  # @param [Symbol] mode              Default: `#date_array_mode`.
  # @param [Regexp] sep               Default: `#date_separator`.
  #
  # @return [Hash]
  #
  def normalize_day_fields!(data, mode = nil, sep = nil)
    data ||= {}
    mode ||= date_array_mode
    sep  ||= date_separator
    day_fields.each do |field|
      next unless data.key?(field)
      value = data[field]
      array = value.is_a?(Array)
      value = value.split(sep).map(&:strip) if value.is_a?(String)
      value = normalize_dates(value)
      result =
        case mode
          when :required  then value
          when :forbidden then value.first
          else                 (array || value.many?) ? value : value.first
        end
      if result.blank?
        Log.debug { "#{__method__}: removing #{field.inspect} field" }
        data.delete(field)
      else
        data[field] = result
      end
    end
    data
  end

  # Produce dates of the form "YYYY-MM-DD".
  #
  # @param [Array<String, Date, Time, IsoDate, Array, nil>] values
  #
  # @return [Array<String>]
  #
  def normalize_dates(*values)
    values.flatten.map { |value| normalize_date(value) }.compact
  end

  # Produce a date of the form "YYYY-MM-DD".
  #
  # @param [String, Date, Time, IsoDate, nil] value
  #
  # @return [String]
  # @return [nil]                     If *value* is not a valid date.
  #
  def normalize_date(value)
    IsoDay.cast(value)&.to_s
  end

end

__loading_end(__FILE__)
