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

  # Limit on the number of individual values to keep for an identifier field.
  #
  # This is necessary because certain IA records have a *absurd* number of
  # :dc_identifier and/or :dc_relation values (2500 in some cases) and there's
  # no benefit in showing (let alone processing) all of those.
  #
  # @type [Integer]
  #
  MAX_IDENTIFIERS = 4

  # Fields involving standard identifiers.
  #
  # @type [Array<Symbol>]
  #
  RELATION_FIELDS = %i[dc_relation dc_identifier].freeze

  # Fields whose value(s) should be prefixed by standard identifier type.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_FIELDS = RELATION_FIELDS

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
  # (The default is :required because this is what EMMA Unified Ingest
  # requires.)
  #
  # @return [Symbol]                  One of #ARRAY_MODES.
  #
  def id_array_mode
    :required
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce standard identifiers of the form "(prefix):(value)".
  #
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  # @param [Hash]                   opt     Passed to #update_field_value!.
  #
  # @option opt [Integer] :limit            Default: #MAX_IDENTIFIERS.
  # @option opt [Symbol]  :mode             Default: `#id_array_mode`.
  #
  # @return [void]
  #
  def normalize_identifier_fields!(data = nil, **opt)
    opt[:limit] ||= MAX_IDENTIFIERS
    opt[:mode]  ||= id_array_mode
    identifier_fields.each do |field|
      update_field_value!(data, field, **opt) { normalize_identifiers(_1) }
    end
  end

  # Produce standard identifiers of the form "(prefix):(value)".
  #
  # @param [String, PublicationIdentifier, Array, nil] values
  #
  # @return [Array<String>]
  #
  def normalize_identifiers(values)
    PublicationIdentifier.objects(values).compact.map!(&:to_s).uniq
  end

  # Produce a standard identifier of the form "(prefix):(value)".
  #
  # @param [String, PublicationIdentifier, nil] value
  #
  # @return [String]
  # @return [nil]                     If *value* is not a valid identifier.
  #
  def normalize_identifier(value)
    PublicationIdentifier.cast(value, invalid: true)&.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Ensure that "related identifiers" doesn't include values which are already
  # included in the reported identifiers for the item.
  #
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  #
  # @return [void]
  #
  # == Usage Notes
  # Make sure that this is invoked after #normalize_identifier_fields! to
  # ensure that #MAX_IDENTIFIERS has been applied to limit the number of array
  # elements in each field.
  #
  def clean_dc_relation!(data = nil)
    related, std_ids = get_field_values(data, *RELATION_FIELDS)
    related = Array.wrap(related) - Array.wrap(std_ids)
    set_field_value!(data, :dc_relation, related)
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
