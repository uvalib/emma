# app/records/concerns/api/shared/common_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General shared methods.
#
module Api::Shared::CommonMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Reduce a string for comparison with another by eliminating surrounding
  # white space and/or punctuation, and by reducing internal runs of white
  # space and/or punctuation to a single space.
  #
  # @param [String]  value
  # @param [Boolean] lowercase        If *false*, preserve case.
  #
  # @return [String]
  #
  def normalized(value, lowercase: true)
    result = value.is_a?(String) ? value.dup : value.to_s
    result = result.downcase if lowercase
    result.sub!(/^[[:space:][:punct:]]+/, '')
    result.sub!(/[[:space:][:punct:]]+$/, '')
    result.gsub!(/[[:space:][:punct:]]+/, ' ')
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the first non-blank value given a list of fields.
  #
  # @param [Array<Symbol>] fields
  #
  # @return [String, nil]
  #
  def get_value(*fields)
    get_values(*fields).first
  end

  # Get the first non-empty value given a list of fields.
  #
  # @param [Array<Symbol>] fields
  #
  # @return [Array<String>]
  #
  def get_values(*fields)
    # noinspection RubyMismatchedReturnType
    fields.find { |meth|
      values = meth && Array.wrap(try(meth)).compact_blank
      break values.map(&:to_s) if values.present?
    } || []
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the indicated field values from the indicated target.
  #
  # @param [Hash, nil]     data       Default: *self*.
  # @param [Array<Symbol>] fields
  #
  # @return [Array]
  #
  def get_field_values(data = nil, *fields)
    data = nil if data == self
    values = data&.values_at(*fields) || fields.map { |field| try(field) }
    values.map(&:presence)
  end

  # Update the indicated target with the given values.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Hash]      values
  #
  # @return [void]
  #
  def set_field_values!(data = nil, values)
    data = nil if data == self
    values = values.compact
    data&.merge!(values) || values.each_pair { |k, v| try("#{k}=", v) }
  end

end

__loading_end(__FILE__)
