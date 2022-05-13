# app/records/lookup/crossref/shared/date_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to dates.
#
module Lookup::Crossref::Shared::DateMethods

  include Lookup::RemoteService::Shared::DateMethods
  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Use the :date_time field if the including class defines it and it has data;
  # otherwise combine :date_parts.
  #
  # @param [Hash] opt                 Passed to #get_date_value.
  #
  # @return [String]
  #
  def as_string(**opt)
    value = get_date_value(**opt)
    value.is_a?(Array) ? DatePart.new(value).as_string : value.to_s
  end

  # Use the :date_time field if the including class defines it and it has data;
  # otherwise combine :date_parts.
  #
  # @param [Hash] opt                 Passed to #get_date_value.
  #
  # @return [Date, nil]
  #
  def to_date(**opt)
    value = get_date_value(**opt)
    value = DatePart.new(value) if value.is_a?(Array)
    value&.to_date
  end

  # Use the :date_time field if the including class defines it and it has data;
  # otherwise combine :date_parts.
  #
  # @param [Hash] opt                 Passed to #get_date_value.
  #
  # @return [DateTime, nil]
  #
  def to_datetime(**opt)
    value = get_date_value(**opt)
    value = DatePart.new(value) if value.is_a?(Array)
    value&.to_datetime
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Recursively find the DateTime or DatePart value.
  #
  # @param [Api::Record] target       Default: `self`.
  # @param [Hash]        opt          Passed to #find_item/#find_items.
  #
  # @return [String, Array<Integer>, nil]
  #
  def get_date_value(target: nil, **opt)
    opt[:target] = find_record_item(:created, target: target) || target
    find_item(:date_time, **opt) || find_items(:date_parts, **opt).first
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  class DatePart < Array

    # @return [Integer]
    def year
      self[0]
    end

    # @return [Integer]
    def month
      self[1] || 1
    end

    # @return [Integer]
    def day
      self[2] || 1
    end

    # @return [String]
    def as_string
      "#{year}-#{month}-#{day}"
    end

    # @return [Date]
    def to_date
      as_string.to_date
    end

    # @return [DateTime]
    def to_datetime
      as_string.to_datetime
    end

  end

  class YearTotal < Array

    # @return [Integer]
    def year
      self[0]
    end

    # @return [Integer]
    def total
      self[1] || 0
    end

  end

end

__loading_end(__FILE__)
