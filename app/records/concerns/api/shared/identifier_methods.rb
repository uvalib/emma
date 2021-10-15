# app/records/concerns/api/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Api::Shared::IdentifierMethods

  include Api::Shared::CommonMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fields whose value(s) should be prefixed by standard identifier type.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_FIELDS =
    %i[dc_identifier dc_relation periodical_identifier].freeze

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
  # @param [Hash, nil] data           Default: *self*
  # @param [Symbol]    mode           Default: `#id_array_mode`.
  # @param [Regexp]    sep            Default: `#id_separator`.
  #
  # @return [void]
  #
  def normalize_identifier_fields!(data = nil, mode = nil, sep = nil)
    mode ||= id_array_mode
    sep  ||= id_separator
    identifier_fields.each do |field|
      value = data ? data[field] : try(field)
      array = value.is_a?(Array)
      value = value.split(sep).map(&:strip) if value.is_a?(String)
      value = normalize_identifiers(value)
      case mode
        when :required  then # Keep value as array.
        when :forbidden then value = value.first
        else                 value = value.first unless array || value.many?
      end
      value = value.presence
      # noinspection RubyNilAnalysis
      if data.nil?
        try("#{field}=", value) if value || try(field)
      elsif value
        data[field] = value
      elsif data.key?(field)
        data.delete(field)
      end
    end
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Ensure that "related identifiers" doesn't include values which are already
  # included in the reported identifiers for the item.
  #
  # @param [Hash, nil] data           Default: *self*.
  #
  # @return [void]
  #
  def clean_dc_relation!(data = nil)
    related = (data ? data[:dc_relation]   : dc_relation).presence   or return
    std_ids = (data ? data[:dc_identifier] : dc_identifier).presence or return
    related = (Array.wrap(related) - Array.wrap(std_ids)).presence
    # noinspection RubyNilAnalysis
    if data.nil?
      self.dc_relation = related
    elsif related
      data[:dc_relation] = related
    elsif data.key?(:dc_relation)
      data.delete(:dc_relation)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The ISBN.
  #
  # @return [String]
  # @return [nil]                     If the value cannot be determined.
  #
  def isbn
  end

  # Related ISBNs omitting the main ISBN if part of the data array.
  #
  # @return [Array<String>]
  #
  def related_isbns
    []
  end

  # The main and related ISBNs.
  #
  # @return [Array<String>]
  #
  def all_isbns
    [isbn, *related_isbns]
  end

end

__loading_end(__FILE__)
