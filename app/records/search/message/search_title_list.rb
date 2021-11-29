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

  # Simulates the :totalResults field of similar Bookshare API records.
  #
  # NOTE: This reports the number of originating search result records.
  #
  # @return [Integer]
  #
  #--
  # noinspection RubyInstanceMethodNamingConvention
  #++
  def totalResults
    records&.size || 0
  end

  # Simulates the :totalResults field of similar Bookshare API records.
  #
  # @return [Integer]
  #
  def item_count
    # noinspection RubyMismatchedReturnType
    titles.size
  end

  alias size   item_count
  alias length item_count

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  DEBUG_AGGREGATE = false

  # Organize metadata records into title records.
  #
  # @param [Search::Message::SearchRecordList, Array<Search::Record::MetadataRecord>, Search::Record::MetadataRecord, nil] src
  #
  # @return [Array<Search::Record::TitleRecord>]
  #
  def aggregate(src)
    # noinspection RubyNilAnalysis
    src   = src.records if src.is_a?(Search::Message::SearchRecordList)
    recs0 = Array.wrap(src).compact_blank
    recs0.group_by { |r| group_fields(r, 0) }.flat_map do |key1, recs1|
      __debug_group(0, key1, recs1)
      recs1.group_by { |r| group_fields(r, 1) }.flat_map do |key2, recs2|
        __debug_group(1, key2, recs2)
        recs2.group_by { |r| group_fields(r, 2) }.flat_map do |key3, recs3|
          __debug_group(2, key3, recs3)
          RECORD_CLASS.new(recs3)
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  GROUPING_LEVELS = [
    %i[emma_titleId],     # primary grouping
    %i[normalized_title], # secondary grouping
    %i[emma_repository],  # tertiary grouping
  ].deep_freeze

  # group_fields
  #
  # @param [Array<Search::Record::MetadataRecord>] records
  # @param [Integer,Symbol,Array<Symbol>]          level
  #
  # @return [Array]
  #
  def group_fields(records, level)
    fields = level.is_a?(Integer) ? GROUPING_LEVELS[level] : Array.wrap(level)
    RECORD_CLASS.extract_fields(records, fields).values
  end

  # Recursive group records.
  #
  # @param [Array<Search::Record::MetadataRecord>] records
  # @param [Integer]                               level
  #
  # @return [Array<Search::Record::TitleRecord>]
  #
  # @note Probably works but isn't being used because the nested approach
  #   generates more useful console debug output.  This method can be used as:
  #   ...
  #   def aggregate(src)
  #     src = src.records if src.is_a?(Search::Message::SearchRecordList)
  #     recursive_grouping(Array.wrap(src).compact_blank)
  #   end
  #
  def recursive_grouping(records, level = 0)
    # noinspection RubyMismatchedParameterType
    groups = records.group_by { |rec| group_fields(rec, level) }.values
    if level.next < GROUPING_LEVELS.size
      groups.flat_map { |recs| recursive_grouping(recs, level.next) }
    else
      groups.map! { |recs| RECORD_CLASS.new(recs) }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  if DEBUG_AGGREGATE
    def __debug_group(level, key, recs)
      leader = '---' * (level + 1)
      field  = key.inspect
      count  = recs.size
      $stderr.puts if level.zero?
      $stderr.puts "#{leader} GROUP_BY #{field} --- (#{count} records)"
    end
  else
    def __debug_group(*)
    end
  end

end

__loading_end(__FILE__)
