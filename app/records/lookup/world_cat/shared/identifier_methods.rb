# app/records/lookup/world_cat/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module Lookup::WorldCat::Shared::IdentifierMethods

  include Lookup::RemoteService::Shared::IdentifierMethods
  include Lookup::WorldCat::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fields containing standard identifier values.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_FIELDS = %i[dc_identifier oclcterms_recordIdentifier].freeze

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
      find_record_items(:dc_identifier).reduce({}) { |result, id|
        id   = PublicationIdentifier.cast(id, invalid: true)
        (key = id&.type) ? result.merge!(key => [*result[key], id]) : result
      }.tap { |result|
        oclc = find_record_items(:oclcterms_recordIdentifier).compact_blank
        ids  = oclc.presence&.map! { |id| Oclc.new(id) }
        type = :oclc
        result.merge!(type => [*result[type], *ids]) if ids
      }.transform_values! { |ids|
        ids.sort_by! { |id| -id.to_s.size }
      }
  end

end

__loading_end(__FILE__)
