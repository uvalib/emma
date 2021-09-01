# app/records/concerns/api/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Api::Shared::IdentifierMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fields whose value(s) should be prefixed by standard identifier type.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_FIELDS = %i[dc_identifier dc_relation].freeze

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

  # Fields whose value(s) should be prefixed by standard identifier type.
  #
  # @return [Array<Symbol>]
  #
  def identifier_fields
    IDENTIFIER_FIELDS
  end

  # Policy for how date multiple date values are handled.
  #
  # (Default is :required because this is what Ingest requires.)
  #
  # @return [Symbol]                  One of #ARRAY_MODES.
  #
  def id_array_mode
    :required
  end

  # The pattern which separates multiple identifiers within a String.
  #
  # @return [Regexp]
  #
  def id_separator
    /[,;|\s]+/
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce standard identifiers of the form "(prefix):(value)".
  #
  # @param [Hash]   data
  # @param [Symbol] mode              Default: `#id_array_mode`.
  # @param [Regexp] sep               Default: `#id_separator`.
  #
  # @return [Hash]
  #
  def normalize_identifier_fields!(data, mode = nil, sep = nil)
    data ||= {}
    mode ||= id_array_mode
    sep  ||= id_separator
    identifier_fields.each do |field|
      next unless data.key?(field)
      value = data[field]
      array = value.is_a?(Array)
      value = value.split(sep).map(&:strip) if value.is_a?(String)
      value = normalize_identifiers(value)
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

  # Produce standard identifiers of the form "(prefix):(value)".
  #
  # @param [Array<String, PublicationIdentifier, Array, nil>] values
  #
  # @return [Array<String>]
  #
  def normalize_identifiers(*values)
    values.flatten.map { |value| normalize_identifier(value) }.compact
  end

  # Produce a standard identifier of the form "(prefix):(value)".
  #
  # @param [String, PublicationIdentifier, nil] value
  #
  # @return [String]
  # @return [nil]                     If *value* is not a valid identifier.
  #
  def normalize_identifier(value)
    PublicationIdentifier.cast(value)&.to_s
  end

end

__loading_end(__FILE__)
