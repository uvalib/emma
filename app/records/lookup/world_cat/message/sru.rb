# app/records/lookup/world_cat/message/sru.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Results from a WorldCat Metadata API v.1 SRU search.
#
# Inside an XML '<searchRetrievalResponse>' element.
#
# @see https://developer.api.oclc.org/wcv1#operations-SRU-search-sru
#
#--
# noinspection LongLine
#++
class Lookup::WorldCat::Message::Sru < Lookup::WorldCat::Api::Message

  include Lookup::WorldCat::Shared::CollectionMethods
  include Lookup::WorldCat::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Lookup::WorldCat::Record::SruRecord

  schema do
    has_one  :version                                                           if EXT
    has_one  :numberOfRecords,              Integer
    has_one  :nextRecordPosition,           Integer
    has_one  :resultSetIdleTime,            Integer                             if ALL
    has_one  :echoedSearchRetrieveRequest,  Lookup::WorldCat::Record::Request   if EXT

    # One or more <record> elements inside a <records> element.
    has_many :records, LIST_ELEMENT, as: :record, wrap: :records
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance and adjust :dc_identifier values.
  #
  # @param [Faraday::Response, Exception Model, Hash, String, nil] src
  # @param [Hash, nil]                                             opt
  #
  def initialize(src = nil, opt = nil)
    super
    records&.each do |rec|
      rec&.recordData&.oclcdcs&.dc_identifier&.map! { |v|
        next if v.blank? || (v = v.to_s).start_with?('http')
        v.include?(':') ? v : "isbn:#{v}"
      }&.compact!
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Overall total number of matching items.
  #
  # @return [Integer]
  #
  def total_results
    numberOfRecords
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::ResponseMethods overrides
  # ===========================================================================

  public

  # api_records
  #
  # @return [Array<Lookup::WorldCat::Record::OclcDcs>]
  #
  def api_records
    Array.wrap(records).map { _1.recordData&.oclcdcs }.compact
  end

end

__loading_end(__FILE__)
