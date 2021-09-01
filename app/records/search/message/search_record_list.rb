# app/records/search/message/search_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchRecordList
#
class Search::Message::SearchRecordList < Search::Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :records, Search::Record::MetadataRecord
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope, RubyMismatchedParameterType
    create_message_wrapper(opt) do |opt|
      apply_wrap!(opt)
      super(src, opt)
    end
  end

  # Simulates the :totalResults field of similar Bookshare API records.
  #
  # @return [Integer]
  #
  #--
  # noinspection RubyInstanceMethodNamingConvention
  #++
  def totalResults
    records&.size || 0
  end

  # ===========================================================================
  # :section: Api::Message overrides
  # ===========================================================================

  protected

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,Boolean}]
  #
  WRAP_FORMATS = { xml: true, json: %q({"records":%{data}}) }.freeze

  # Update *opt[:wrap]* according to the supplied formats.
  #
  # @param [Hash] opt                 May be modified.
  #
  # @return [void]
  #
  def apply_wrap!(opt)
    super(opt, WRAP_FORMATS)
  end

end

__loading_end(__FILE__)
