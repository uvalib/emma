# app/records/lookup/world_cat/record/open_search_entry.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Partial record schema for WorldCat API results.
#
# @attr [Array<String>] author
# @attr [Array<String>] title
# @attr [String]        link                        # NOTE: Fields [1]
# @attr [String]        id                          # NOTE: Fields [2]
# @attr [DateTime]      updated                     # NOTE: Fields [3]
# @attr [String]        summary
# @attr [Array<String>] dc_identifier               # NOTE: Fields [4]
# @attr [String]        oclcterms_recordIdentifier  # NOTE: Fields [5]
#
# == Fields
# [1] :link
#   * URL to WorldCat OCLC entry in 'href' attribute.
# [2] :id
#   * URL to WorldCat OCLC entry.
# [3] :updated
#   * Last update of the index entry (?)
# [4] :dc_identifier
#   * Standard identifier URN; e.g.:
#     'urn:ISBN:9783958091016'
#     'urn:ISBN:3958091016'
#     'urn:LCCN:74013958'
# [5] :oclcterms_recordIdentifier
#   * The OCLC number (value only; no "oclc:", "ocm", "ocn", etc. prefix)
#
# @see https://developer.api.oclc.org/wcv1#operations-tag-OpenSearch
#
# == Usage Notes
# Generally this information is too sparse for purposes of bibliographic
# metadata lookup.
#
class Lookup::WorldCat::Record::OpenSearchEntry < Lookup::WorldCat::Api::Record

  include Lookup::WorldCat::Shared::CreatorMethods
  include Lookup::WorldCat::Shared::DateMethods
  include Lookup::WorldCat::Shared::IdentifierMethods
  include Lookup::WorldCat::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :author,                     Lookup::WorldCat::Record::Author
    has_many :title
    has_one  :link
    has_one  :id
    has_one  :updated,                    DateTime
    has_one  :summary
    has_many :dc_identifier
    has_one  :oclcterms_recordIdentifier
  end

end

__loading_end(__FILE__)
