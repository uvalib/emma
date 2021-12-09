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

  public

  # Normalization array handling.
  #
  # :required   Results always given as arrays.
  # :forbidden  Results are only given a singles.
  # :auto       Results given as arrays when indicated; singles otherwise.
  #
  # @type [Array<Symbol>]
  #
  ARRAY_MODES = %i[auto required forbidden].freeze

  # Generic separator for splitting a string into parts.
  #
  # @type [Regexp]
  #
  PART_SEPARATOR = /[|\t\n]+/.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  PRODUCTION_HOST = URI.parse(PRODUCTION_BASE_URL).host.freeze rescue nil

  # Indicate whether this record represents a canonical index entry.
  #
  # In production, for EMMA repository items, this would mean an entry whose
  # :emma_retrievalLink starts with the base URL for the production service.
  #
  # @param [Api::Record, nil] rec  Default: `self`.
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def canonical?(rec = nil)
    rec ||= self
    if (elements = rec.try(:elements))
      elements.all?(&:canonical?)
    else
      local = (rec.try(:emma_repository) == EmmaRepository.default)
      url   = (rec.try(:emma_retrievalLink)   if local)
      host  = (URI.parse(url).host rescue nil if url.present?)
      host.blank? || (host == PRODUCTION_HOST)
    end
  end

  # Indicate whether this record represents a canonical index entry.
  #
  # In production, for EMMA repository items, this would mean an entry whose
  # :emma_retrievalLink starts with the base URL for the production service.
  #
  # @param [Api::Record, nil] rec  Default: `self`.
  #
  def empty?(rec = nil)
    rec ||= self
    # noinspection RubyNilAnalysis
    if (contained = rec.try(:elements)).nil?
      rec.fields.values.all?(&:blank?)
    else
      contained.blank?
    end
  end

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

  # Get the target field value.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Symbol]    field
  #
  # @return [*]
  #
  def get_field_value(data, field)
    data.is_a?(Hash) ? data[field] : try(field)
  end

  # Set the target field value.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Symbol]    field
  # @param [*]         value
  #
  # @return [void]
  #
  def set_field_value!(data, field, value)
    value = value.presence
    # noinspection RubyNilAnalysis
    if !data.is_a?(Hash)
      try("#{field}=", value)
    elsif value
      data[field] = value
    elsif data.key?(field)
      data.delete(field)
    end
  end

  # Update the target field.
  #
  # @param [Hash, nil]   data         Default: *self*.
  # @param [Symbol]      field
  # @param [Symbol, nil] mode         One of #ARRAY_MODES.
  #
  # @return [void]
  #
  # @yield [value] Generate a replacement value
  # @yieldparam [*] value   The current field value.
  # @yieldreturn [Array]    The new field value(s).
  #
  def update_field_value!(data, field, mode = nil)
    value = get_field_value(data, field)
    array = value.is_a?(Array)
    value = yield(value)
    case mode
      when :required  then # Keep value as array.
      when :forbidden then value = value.first
      else                 value = value.first unless array || value.many?
    end
    set_field_value!(data, field, value)
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
  def get_field_values(data, *fields)
    # noinspection RubyNilAnalysis
    v = data.is_a?(Hash) ? data.values_at(*fields) : fields.map { |f| try(f) }
    v.map(&:presence)
  end

  # Update the indicated target with the given values.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Hash]      values
  #
  # @return [void]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def set_field_values!(data, values)
    if data.is_a?(Hash)
      deletions = values.select { |_, v| v.blank? }.keys.presence
      values.except!(*deletions) if deletions
      data.except!(*deletions)   if deletions
      data.merge!(values)
    else
      values.each_pair { |k, v| try("#{k}=", v) }
    end
  end

end

__loading_end(__FILE__)
