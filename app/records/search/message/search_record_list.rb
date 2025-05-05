# app/records/search/message/search_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchRecordList
#
class Search::Message::SearchRecordList < Search::Api::Message

  include Search::Shared::CollectionMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Search::Record::MetadataRecord

  schema do
    has_many :records, LIST_ELEMENT
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Model, Hash, String, nil] src
  # @param [Hash, nil]                                   opt
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      apply_wrap!(opt)
      super(src, opt)
      records.each(&:normalize_data_fields!)
    end
  end

  # Overall total number of matching items.
  #
  # @return [Integer]
  #
  def total_results
    records&.size || 0
  end

  # Update records by calculating "relevance scores".
  #
  # @param [String, Array<String>] terms  Given to all score methods if present
  # @param [Hash]                  opt    Search parameters.
  #
  # @return [void]

  def calculate_scores!(terms = nil, **opt)
    records.each do |rec|
      rec.calculate_scores!(terms, **opt)
    end
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
