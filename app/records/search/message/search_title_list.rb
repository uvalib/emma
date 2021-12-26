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
    %i[dc_identifier dc_creator dc_publisher emma_publicationDate]
  ].deep_freeze

  # @private
  GROUPING_LEVEL_DEPTH = GROUPING_LEVELS.size

  class BottomLevel

    include Comparable

    # @private
    IDENTIFIER_FIELDS = Api::Shared::IdentifierMethods::IDENTIFIER_FIELDS

    # @return [PublicationIdentifierSet, nil]
    attr_reader :ids

    # @return [Array]
    attr_reader :values

    def initialize(hash)
      @ids    = nil
      @values = []
      hash.each_pair do |field, value|
        if IDENTIFIER_FIELDS.include?(field)
          @ids = PublicationIdentifierSet.new(value)
        else
          @values << LIST_ELEMENT.make_comparable(value, field)
        end
      end
      $stderr.puts "@@@@@@@ BottomLevel.ctor | #{self.inspect}"
    end

    # =========================================================================
    # :section: Object overrides
    # =========================================================================

    public

    def hash
      # NOTE: so, since group_by is using #hash it's going to be pretty difficult to override equality...
      #   Bottom line -- it may be necessary to implement an analogue to group_by which uses eql?()
      #super
      (
        ids ? ids.hash : values.hash
        #ids ? 0 : values.hash
      )
        .tap { |res| $stderr.puts "@@@@@@@ BottomLevel.hash | #{res.inspect} | #{self.inspect}" }
    end

    def eql?(other)
      return false unless other.is_a?(BottomLevel)
      (
      ids && (ids == other.ids) || (values == other.values)
      )
        .tap { |res| $stderr.puts "@@@@@@@ BottomLevel.eql? | #{res.inspect} | #{self.inspect} | #{other.inspect}" }
    end

    def ==(other)
      $stderr.puts '@@@@@@@ BottomLevel.=='
      eql?(other)
    end

  end

  # group_fields
  #
  # @param [Search::Record::MetadataRecord] rec
  # @param [Integer, Symbol, Array<Symbol>] level
  #
  # @return [Array]
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
    BottomLevel.new(LIST_ELEMENT.extract_fields(rec, fields))
=begin
    LIST_ELEMENT.extract_fields(rec, fields).map do |field, value|
      if IDENTIFIER_FIELDS.include?(field)
        PublicationIdentifierSet.new(value)
      else
        LIST_ELEMENT.make_comparable(value, field)
      end
        .tap { |res| $stderr.puts "@@@@@@@ group_fields | #{res.inspect} | #{field.inspect} | #{value.inspect} | -> #{res.inspect}" }
    end
=end
    #LIST_ELEMENT.comparable_fields(rec, fields).values
  end

  # Recursively group records.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
  # @param [Integer]       level      Incremented via recursion.
  # @param [Array<Symbol>] fields     Supplied via recursion.
  # @param [Proc]          block      Executed at the bottom-level.
  #
  # @return [Array<Search::Record::TitleRecord>]
  #
  # @yield [recs] Create a title-level record from field-level records.
  # @yieldparam  [Array<Search::Record::MetadataRecord>] recs
  # @yieldreturn [Search::Record::TitleRecord, nil]
  #
  def recursive_group_records(recs, level: 0, fields: [], &block)
    __debug_group(level, fields, recs) if level.positive?
    return block.call(recs) if level == GROUPING_LEVEL_DEPTH
    recs.group_by { |r| group_fields(r, level) }.flat_map { |_flds, _recs|
      recursive_group_records(_recs, level: (level+1), fields: _flds, &block)
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
