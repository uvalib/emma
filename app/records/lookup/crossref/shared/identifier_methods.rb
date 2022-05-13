# app/records/lookup/crossref/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Lookup::Crossref::Shared::IdentifierMethods

  include Lookup::RemoteService::Shared::IdentifierMethods
  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A table of identifier attributes with their associated
  # PublicationIdentifier subclasses.
  #
  # @type [Hash{Symbol=>Class<PublicationIdentifier>}]
  #
  FIELD_TYPE_MAP = {
    doi:  Doi,
    issn: Issn,
    isbn: Isbn,
  }.freeze

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::IdentifierMethods overrides
  # ===========================================================================

  public

  # identifier_list
  #
  # @return [Array<String>]
  #
  def identifier_list
    @identifier_list ||= super
  end

  # identifier_table
  #
  # @return [Hash{Symbol=>Array<PublicationIdentifier>}]
  #
  def identifier_table
    @identifier_table ||=
      FIELD_TYPE_MAP.map { |field, type|
        next if (values = find_record_values(field)).blank?
        values.sort_by! { |v| -v.size }
        values.map!     { |v| type.new(v) }
        [field, values]
      }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Related :dc_identifier (and possibly) :dc_relation.
  #
  # If a DOI is present then it is assumed that
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def identifier_related
    all = identifier_table.transform_values! { |ids| ids.map(&:to_s) }
    result = {}
    if (item = extract_hash!(all, :doi, :isbn)).present?
      result[:dc_identifier] = item.values.flatten
      result[:dc_relation]   = all.values.flatten  if all.present?
    else
      result[:dc_identifier] = all.values.flatten  if all.present?
    end
    result
  end

end

__loading_end(__FILE__)
