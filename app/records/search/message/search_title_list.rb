# app/records/search/message/search_title_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchTitleList
#
class Search::Message::SearchTitleList < Search::Api::Message

  include Search::Shared::CollectionMethods
  include Search::Shared::IdentifierMethods

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
    # noinspection RubyScope, RubyMismatchedArgumentType
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

  # Overall total number of matching records.
  #
  # NOTE: This reports the number of originating search result records.
  #
  # @return [Integer]
  #
  def total_results
    records&.size || 0
  end

  # Overall total number of matching titles.
  #
  # @return [Integer]
  #
  def item_count
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

  # @private
  # @type [Array<Array<Symbol>>]
  GROUPING_LEVELS = Search::Record::TitleRecord::GROUPING_LEVELS

  # @private
  GROUPING_LEVEL_DEPTH = GROUPING_LEVELS.size

  # Encapsulates a subset of field values to provide a single object for use
  # with Enumerable#group_by.
  #
  # === Implementation Notes
  # This is still under development because the intent was to dynamically
  # vary the comparison criteria if standard ID(s) are present, however
  # Enumerable#group_by uses #hash not #eql?.
  #
  # It may be necessary to implement an analogue to #group_by which uses #eql?
  # for this to work out as intended.
  #
  class GroupingCriteria

    include Comparable
    include Emma::Common

    # @private
    IDENTIFIER_FIELDS = Api::Shared::IdentifierMethods::IDENTIFIER_FIELDS

    # @return [PublicationIdentifierSet, nil]
    attr_reader :ids

    # @return [Array, nil]
    attr_reader :values

    def initialize(hash)
      id, val = partition_hash(hash, *IDENTIFIER_FIELDS)
      @ids    = [*id.values].compact_blank.presence
      @ids  &&= PublicationIdentifierSet.new(@ids)
      @values = val.values.map { LIST_ELEMENT.make_comparable(_1) }.presence
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the other value is similar to the current value.
    #
    # @param [any, nil] other
    #
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
      # @type [Hash{Symbol=>Array,String,nil}]
      part = { ids: ids&.to_a, values: values }
      part.transform_values! { _1&.map(&:inspect)&.join(', ') }
      part[:ids]&.remove!('()')
      part.transform_values! { _1 || '---' }
      '<%{ids} | %{values} | GroupingCriteria>' % part
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
    GroupingCriteria.new(LIST_ELEMENT.field_values(rec, *fields))
  end

  # Recursively group records.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
  # @param [Integer]  level           Incremented via recursion.
  # @param [any, nil] fields          Supplied via recursion.
  # @param [Proc]     blk             Executed at the bottom-level.
  #
  # @return [Array<Search::Record::TitleRecord>]
  # @return [Search::Record::TitleRecord, nil]
  #
  # @yield [recs] Create a title-level record from field-level records.
  # @yieldparam  [Array<Search::Record::MetadataRecord>] recs
  # @yieldreturn [Search::Record::TitleRecord, nil]
  #
  def recursive_group_records(recs, level: 0, fields: nil, &blk)
    __debug_group(level, fields, recs) if level.positive?
    return blk.call(recs) if level == GROUPING_LEVEL_DEPTH
    group_related(recs, level).flat_map { |flds, group|
      recursive_group_records(group, level: (level+1), fields: flds, &blk)
    }.compact_blank
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
      if (related = result.keys.find { _1.match?(criteria) })
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
      __output if level.zero?
      __output "#{leader} GROUP_BY #{fields} --- (#{count} records)"
    end
  else
    def __debug_group(...)
    end
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # The fields and values for this instance as a Hash.
  #
  # If *item* is not blank this is used as an indicator that individual records
  # should be wrapped (i.e., that the intended output format is XML).
  #
  # @param [any, nil] item
  #
  # @return [Hash]
  #
  def to_h(item: nil, **)
    super.tap do |result|
      if item.present?
        result[:titles]&.map! do |title|
          title[:records].map! { |rec| { record: rec } }
        end
      end
    end
  end

end

__loading_end(__FILE__)
