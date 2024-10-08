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

  # Fields that must be transmitted as "YYYY-MM-DD".
  #
  # @return [Array<Symbol>]
  #
  def day_fields
    []
  end

  # Policy for how date multiple date values are handled.
  #
  # (The default is :forbidden because this is what EMMA Unified Ingest
  # requires.)
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
    PART_SEPARATOR
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  TITLE_DATE_FIELDS = %i[dcterms_dateCopyright emma_publicationDate].freeze

  # Back-fill publication date / copyright date.
  #
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  #
  # @return [void]
  #
  def normalize_title_dates!(data = nil)
    cpr, pub = get_field_values(data, *TITLE_DATE_FIELDS)
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
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  # @param [Hash]                   opt     Passed to #update_field_value!.
  #
  # @option opt [Symbol] :mode              Default: `#date_array_mode`.
  #
  # @return [void]
  #
  def normalize_day_fields!(data = nil, **opt)
    opt[:mode] ||= date_array_mode
    day_fields.each do |field|
      update_field_value!(data, field, **opt) { normalize_dates(_1) }
    end
  end

  # Produce dates of the form "YYYY-MM-DD".
  #
  # @param [String, Date, Time, IsoDate, Array, nil] values
  #
  # @return [Array<String>]
  #
  def normalize_dates(values)
    values = values.split(date_separator) if values.is_a?(String)
    Array.wrap(values).map { normalize_date(_1) }.compact
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
