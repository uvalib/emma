# app/records/lookup/world_cat/record/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Partial record schema for WorldCat API results.
#
# @attr [String] recordSchema   'info:srw/schema/1/dc'
# @attr [String] recordPacking  'xml'
#
# @see https://developer.api.oclc.org/wcv1#operations-SRU-search-sru
#
#--
# noinspection LongLine
#++
class Lookup::WorldCat::Record::Response < Lookup::WorldCat::Api::Record

  include Lookup::WorldCat::Shared::CollectionMethods
  include Lookup::WorldCat::Shared::IdentifierMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Lookup::WorldCat::Record::SruRecord

  schema do
    has_one  :version                                                           if EXT
    has_one  :numberOfRecords,              Integer
    has_many :records,                      LIST_ELEMENT
    has_one  :nextRecordPosition,           Integer
    has_one  :resultSetIdleTime                                                 if ALL # TODO: ???
    has_one  :echoedSearchRetrieveRequest,  Lookup::WorldCat::Record::Request   if EXT
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
  # noinspection RubyInstanceMethodNamingConvention, RubyMismatchedReturnType
  #++
  def totalResults
    numberOfRecords
  end

end

__loading_end(__FILE__)
