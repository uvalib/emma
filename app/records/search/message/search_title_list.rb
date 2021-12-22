# app/records/search/message/search_title_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchTitleList
#
class Search::Message::SearchTitleList < Search::Api::Message

  include Search::Shared::CollectionMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  LIST_ELEMENT = Search::Record::TitleRecord

  schema do
    has_many :titles, LIST_ELEMENT
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The original metadata records in the original order.
  #
  # @return [Array<Search::Record::MetadataRecord>]
  #
  attr_reader :records

  # Indicate whether only canonical records will be used.
  #
  # @return [Boolean]
  #
  attr_reader :canonical

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Search::Message::SearchRecordList, nil] src
  # @param [Hash, nil]                              opt   To super except:
  #
  # @option opt [Boolean, nil] :canonical   Passed to #aggregate.
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope, RubyMismatchedArgumentType, RubyNilAnalysis
    create_message_wrapper(opt) do |opt|
      @canonical = opt.delete(:canonical)
      apply_wrap!(opt)
      super(nil, opt)
      @records    = Array.wrap(src.try(:records) || src).compact
      self.titles = aggregate
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # @param [Array<Search::Record::MetadataRecord>, nil] src  Default: `records`
  # @param [Hash]                                       opt  To TitleRecord
  #
  # @return [Array<Search::Record::TitleRecord>]
  #
  def aggregate(src = nil, **opt)
    opt[:canonical] = canonical unless opt.key?(:canonical)
    recs0 = src ? Array.wrap(src).compact_blank : records
    recs0.group_by { |r| group_fields(r, 0) }.flat_map { |key1, recs1|
      __debug_group(0, key1, recs1)
      recs1.group_by { |r| group_fields(r, 1) }.flat_map { |key2, recs2|
        __debug_group(1, key2, recs2)
        recs2.group_by { |r| group_fields(r, 2) }.flat_map { |key3, recs3|
          __debug_group(2, key3, recs3)
          # noinspection RubyMismatchedReturnType
          LIST_ELEMENT.new(recs3, **opt)
        }.compact_blank!
      }.compact_blank!
    }.compact_blank!
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
  # @param [Search::Record::MetadataRecord] rec
  # @param [Integer,Symbol,Array<Symbol>]   level
  #
  # @return [Array]
  #
  def group_fields(rec, level)
    fields = level.is_a?(Integer) ? GROUPING_LEVELS[level] : Array.wrap(level)
    LIST_ELEMENT.extract_fields(rec, fields).values
  end

  # Recursive group records.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
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
  def recursive_grouping(recs, level = 0)
    groups = recs.group_by { |rec| group_fields(rec, level) }.values
    if level.next < GROUPING_LEVELS.size
      groups.flat_map { |group| recursive_grouping(group, level.next) }
    else
      # noinspection RubyMismatchedReturnType
      groups.map! { |group| LIST_ELEMENT.new(group) }
    end
  end

  # ===========================================================================
  # :section: Api::Record overrides
  # ===========================================================================

  public

  # The fields and values for this instance as a Hash.
  #
  # If opt[:item] is present, this is used as an indicator that individual
  # records should be wrapped (i.e., that the intended output format is XML).
  #
  # @param [Hash] opt                 Passed to Api::Record#to_h.
  #
  def to_h(**opt)
    super(**opt).tap do |result|
      if opt[:item].present?
        result[:titles]&.map! do |title|
          title[:records].map! { |rec| { record: rec } }
        end
      end
    end
  end

end

__loading_end(__FILE__)
