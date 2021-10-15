# app/records/concerns/api/shared/date_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to dates.
#
module Api::Shared::DateMethods

  include Api::Shared::CommonMethods

  extend self

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

  # @private
  TITLE_DATE_FIELDS = %i[dcterms_dateCopyright emma_publicationDate].freeze

  # Back-fill publication date / copyright date.
  #
  # @param [Hash, nil] data           Default: *self*.
  #
  # @return [void]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def normalize_title_dates!(data = nil)
    cpr, pub = get_field_values(data, TITLE_DATE_FIELDS)
    if cpr && pub
      cpr, pub = []
    elsif cpr
      cpr, pub = [nil, IsoDay.cast(cpr)&.to_s]
    elsif pub
      cpr, pub = [IsoYear.cast(pub)&.to_s, nil]
    end
    values = { dcterms_dateCopyright: cpr, emma_publicationDate: pub }.compact
    set_field_values!(data, values) if values.present?
  end

  # Produce day values of the form "YYYY-MM-DD".
  #
  # @param [Hash, nil] data           Default: *self*
  # @param [Symbol]    mode           Default: `#date_array_mode`.
  # @param [Regexp]    sep            Default: `#date_separator`.
  #
  # @return [void]
  #
  def normalize_day_fields!(data = nil, mode = nil, sep = nil)
    mode ||= date_array_mode
    sep  ||= date_separator
    day_fields.each do |field|
      value = data ? data[field] : try(field)
      array = value.is_a?(Array)
      value = value.is_a?(String) ? value.split(sep) : Array.wrap(value)
      value = normalize_dates(value)
      case mode
        when :required  then # Keep value as array.
        when :forbidden then value = value.first
        else                 value = value.first unless array || value.many?
      end
      value = value.presence
      # noinspection RubyNilAnalysis
      if data.nil?
        try("#{field}=", value) if value
      elsif value
        data[field] = value
      elsif data.key?(field)
        data.delete(field)
      end
    end
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
    IsoDay.cast(value)&.to_s if value.present?
  end

end

__loading_end(__FILE__)
