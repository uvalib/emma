# app/records/lookup/world_cat/record/request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Partial record schema for WorldCat API results.
#
# For '<echoedSearchRetrieveRequest xmlns:srw="http://www.loc.gov/zing/srw/">'
# XML element.
#
# @attr [String]  version           "1.1"
# @attr [String]  query             The search portion of the URL.
# @attr [Integer] maximumRecords    Results page size.
# @attr [String]  recordSchema      "info:srw/schema/1/dc"
# @attr [String]  recordPacking     "xml"
# @attr [Integer] startRecord       Index of first entry in the total results.
# @attr [String]  sortKeys          E.g.: "relevance"
# @attr [String]  wskey
# @attr [String]  serviceLevel      "full" or "default"
#
# @see https://developer.api.oclc.org/wcv1#operations-SRU-search-sru
#
class Lookup::WorldCat::Record::Request < Lookup::WorldCat::Api::Record

  include Lookup::WorldCat::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  # noinspection SpellCheckingInspection
  schema do
    has_one :version
    has_one :query
    has_one :maximumRecords, Integer
    has_one :recordSchema
    has_one :recordPacking
    has_one :startRecord,    Integer
    has_one :sortKeys
    has_one :wskey
    has_one :servicelevel
  end

end

__loading_end(__FILE__)
