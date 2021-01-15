# app/records/search/message/search_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchRecordList
#
class Search::Message::SearchRecordList < Search::Api::Message

  schema do
    has_many :records, Search::Record::MetadataRecord
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,Boolean}]
  #
  WRAP_FORMATS = { xml: true, json: %q({"records":%{data}}) }.freeze

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      if opt[:wrap].nil? || opt[:wrap].is_a?(Hash)
        opt[:wrap] = WRAP_FORMATS.merge(opt[:wrap] || {})
      end
      super(src, **opt)
    end
  end

  # Simulates the :totalResults field of similar Bookshare API records.
  #
  # @return [Integer]
  #
  #--
  # noinspection RubyInstanceMethodNamingConvention, RubyYardReturnMatch
  #++
  def totalResults
    records&.size || 0
  end

end

__loading_end(__FILE__)
