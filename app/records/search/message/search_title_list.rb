# app/records/search/message/search_title_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchTitleList
#
class Search::Message::SearchTitleList < Search::Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  RECORD_CLASS = Search::Record::TitleRecord

  schema do
    has_many :titles, RECORD_CLASS
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Search::Message::SearchRecordList, nil] src
  # @param [Hash, nil]                              opt
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope, RubyMismatchedParameterType
    create_message_wrapper(opt) do |opt|
      apply_wrap!(opt)
      super(nil, opt)
      self.titles = aggregate(src)
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
  # :section:
  # ===========================================================================

  public

  # The original metadata records in title order.
  #
  # @return [Array<Search::Record::MetadataRecord>]
  #
  def records
    @records ||= titles&.flat_map(&:records)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Organize metadata records into title records.
  #
  # @param [Search::Message::SearchRecordList, Array<Search::Record::MetadataRecord>, Search::Record::MetadataRecord, nil] src
  #
  # @return [Array<Search::Record::TitleRecord>]
  #
  def aggregate(src)
    # noinspection RubyNilAnalysis
    src = src.records if src.is_a?(Search::Message::SearchRecordList)
    @records = Array.wrap(src).compact_blank.deep_dup
    @records
      .group_by { |rec| RECORD_CLASS.match_fields(rec).values }
      .map { |_, recs| RECORD_CLASS.new(recs) } || []
  end

end

__loading_end(__FILE__)
