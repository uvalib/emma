# app/records/lookup/world_cat/message/open_search.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Results from a WorldCat Metadata API v.1 OpenSearch search.
#
# Inside an XML '<feed>' element.
#
# @attr [String]   title      A description of the search performed.
# @attr [String]   subtitle   A longer description of the search performed.
# @attr [String]   id         Full URL for the search performed.
# @attr [DateTime] updated    When the search was performed.
#
# @see https://developer.api.oclc.org/wcv1#operations-tag-OpenSearch
#
class Lookup::WorldCat::Message::OpenSearch < Lookup::WorldCat::Api::Message

  include Lookup::WorldCat::Shared::CollectionMethods
  include Lookup::WorldCat::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Lookup::WorldCat::Record::OpenSearchEntry

  schema do
    has_one  :title
    has_one  :subtitle
    has_one  :id
    has_one  :updated,                  DateTime
    has_one  :opensearch_totalResults,  Integer
    has_one  :opensearch_startIndex,    Integer
    has_one  :opensearch_itemsPerPage,  Integer
    has_one  :opensearch_Query
    has_many :link
    has_many :entry,                    LIST_ELEMENT
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Simulates the :totalResults field of similar Bookshare API records.
  #
  # @return [Integer]
  #
  #--
  # noinspection RubyInstanceMethodNamingConvention
  #++
  def totalResults
    opensearch_totalResults
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::ResponseMethods overrides
  # ===========================================================================

  public

  # api_records
  #
  # @return [Array<Lookup::WorldCat::Record::SruRecord>]
  #
  def api_records
    Array.wrap(entry)
  end

end

__loading_end(__FILE__)
