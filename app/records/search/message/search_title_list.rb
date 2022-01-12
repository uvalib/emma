# app/records/search/message/search_title_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchTitleList
#
class Search::Message::SearchTitleList < Search::Api::Message

  include Search::Shared::IdentifierMethods
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
      @canonical  = opt.delete(:canonical)
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
  DEBUG_AGGREGATE = true

  # Organize metadata records into title records.
  #
  # @param [Array<Search::Record::MetadataRecord>, nil] src  Default: `records`
  # @param [Hash]                                       opt  To TitleRecord
  #
  # @return [Array<Search::Record::TitleRecord>]
  #
  def aggregate(src = nil, **opt)
    opt[:canonical] = canonical unless opt.key?(:canonical)
    file_level_records = src ? Array.wrap(src).compact_blank : records
    # noinspection RubyMismatchedReturnType
    recursive_group_records(file_level_records) do |records_for_title|
      LIST_ELEMENT.new(records_for_title, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Each grouping involves one or more Search::Record::MetadataRecord fields
  # (or other instance methods).
  #
  # @type [Array<Array<Symbol>>]
  #
  GROUPING_LEVELS = [
    %i[normalized_title],
    %i[emma_repository],
    %i[dc_creator dc_publisher emma_publicationDate]
  ].deep_freeze

  # @private
  GROUPING_LEVEL_DEPTH = GROUPING_LEVELS.size

  # Encapsulates a subset of field values to provide a single object for use
  # with Enumerable#group_by.
  #
  # == Implementation Notes
  # This is still under development because the intent was to dynamically
  # vary the comparison criteria if standard ID(s) are present, however
  # Enumerable#group_by uses #hash not #eql?.
  #
  # It may be necessary to implement an analogue to #group_by which uses #eql?
  # for this to work out as intended.
  #
  class GroupingCriteria

    include Comparable

    # @private
    IDENTIFIER_FIELDS = Api::Shared::IdentifierMethods::IDENTIFIER_FIELDS

    # @return [PublicationIdentifierSet, nil]
    attr_reader :ids

    # @return [Array, nil]
    attr_reader :values

    def initialize(hash)
      id, val = partition_hash(hash, *IDENTIFIER_FIELDS)
      @ids    = [*id.values].compact_blank!.presence
      @ids  &&= PublicationIdentifierSet.new(@ids)
      @values = val.values.map { |v| LIST_ELEMENT.make_comparable(v) }.presence
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the other value is similar to the current value.
    #
    # @param [Any] other
    #
    #--
    # noinspection RubyNilAnalysis, RubyMismatchedArgumentType
    #++
    def match?(other)
      return false unless other.is_a?(GroupingCriteria)
      return true  if ids && other.ids && ids.intersect?(other.ids)
      return true  if values == other.values
      return false if values.blank? || other.values.blank?
      values.each_with_index.all? do |v, i|
        v.blank? || other.values[i].blank? || (v == other.values[i])
      end
    end

    # =========================================================================
    # :section: Object overrides
    # =========================================================================

    public

    def hash
      ids&.hash || values.hash
    end

    def eql?(other)
      ids && (ids == other.ids) || (values == other.values)
    end

    def ==(other)
      eql?(other)
    end

    def inspect
      i_list = ids ? ids.to_a.map(&:inspect).join(', ').tr('()', '') : '---'
      v_list = values.map(&:inspect).join(', ')
      "<#{i_list} | #{v_list} | GroupingCriteria>"
    end

  end

  # group_fields
  #
  # @param [Search::Record::MetadataRecord] rec
  # @param [Integer, Symbol, Array<Symbol>] level
  #
  # @return [GroupingCriteria]
  #
  def group_fields(rec, level)
    fields = []
    if !level.is_a?(Integer)
      fields = Array.wrap(level)
    elsif (range = 0...GROUPING_LEVEL_DEPTH).cover?(level)
      fields = GROUPING_LEVELS[level]
    else
      Log.error { "#{__method__}: level #{level} not in range #{range}" }
    end
    GroupingCriteria.new(LIST_ELEMENT.extract_fields(rec, fields))
  end

  # Recursively group records.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
  # @param [Integer] level            Incremented via recursion.
  # @param [Any]     fields           Supplied via recursion.
  # @param [Proc]    block            Executed at the bottom-level.
  #
  # @return [Array<Search::Record::TitleRecord>]
  # @return [Search::Record::TitleRecord, nil]
  #
  # @yield [recs] Create a title-level record from field-level records.
  # @yieldparam  [Array<Search::Record::MetadataRecord>] recs
  # @yieldreturn [Search::Record::TitleRecord, nil]
  #
  def recursive_group_records(recs, level: 0, fields: nil, &block)
    __debug_group(level, fields, recs) if level.positive?
    return block.call(recs) if level == GROUPING_LEVEL_DEPTH
    group_related(recs, level).flat_map { |flds, group|
      # noinspection RubyMismatchedReturnType
      recursive_group_records(group, level: (level+1), fields: flds, &block)
    }.compact_blank!
  end

  # This functions as an alternative to Enumerable#group_by, but grouping by
  # similarity rather than identity.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
  # @param [Integer]                               level
  #
  # @return [Hash{GroupingCriteria=>Array<Search::Record::MetadataRecord>}]
  #
  def group_related(recs, level)
    result = {}
    recs.each do |rec|
      criteria = group_fields(rec, level)
      if (related = result.keys.find { |key| key.match?(criteria) })
        result[related] << rec
      else
        result[criteria] = [rec]
      end
    end
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  if DEBUG_AGGREGATE
    def __debug_group(level, fields, recs)
      leader = '---' * (level + 1)
      fields = fields.inspect
      count  = recs.size
      $stderr.puts if level.zero?
      $stderr.puts "#{leader} GROUP_BY #{fields} --- (#{count} records)"
    end
  else
    def __debug_group(...)
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
