# app/records/search/record/title_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search results aggregated under a single title from a specific repository.
#
# Each item in :records will have the same values for :emma_titleId, :dc_title,
# and :emma_repository, but will have differing values for :dc_format and/or
# :dc_description.
#
class Search::Record::TitleRecord < Search::Api::Record

  include Search::Shared::CreatorMethods
  include Search::Shared::DateMethods
  include Search::Shared::IdentifierMethods
  include Search::Shared::LinkMethods
  include Search::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  RECORD_CLASS = Search::Record::MetadataRecord

  schema do
    has_many :records, RECORD_CLASS
  end

  delegate_missing_to :exemplar

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Data extraction methods appropriate as either instance- or class-methods.
  #
  module Methods

    include Emma::Common
    include Emma::Unicode

    # =========================================================================
    # :section:
    # =========================================================================

    public

    DEFAULT_LEVEL_NAME = 'v.'

    MATCH_FIELDS = %i[emma_titleId normalized_title emma_repository].freeze

    SORT_FIELDS = %i[title repository item_number format item_date].freeze

    # A pattern matching a complete level name and value, where:
    #
    #   $1 is the level name
    #   $2 is a number, or a sequence of numbers/ranges
    #
    # @type [Regexp]
    #
    NUMBER_PATTERN =
      /([[:alpha:].]+)\s*(\d[\d\s&,#{EN_DASH}#{EM_DASH}-]*)\s*/.freeze

    # A pattern matching a likely item number.
    #
    # @type [Regexp]
    #
    LEADING_ITEM_NUMBER = Regexp.new('^' + NUMBER_PATTERN.source).freeze

    # A pattern matching a likely year number.
    #
    # @type [Regexp]
    #
    YEAR_PATTERN = /(?<=^|\W)(\d{4})(?=\W|$)/.freeze

    # A pattern seen for years appended to item numbers.
    #
    # @type [Regexp]
    #
    TRAILING_YEAR = /(?<=^|[^\d])(\d{4})[)\s]*$/.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Normalize a level numbering name.
    #
    # @param [String]
    #
    # @return [String]
    #
    def number_name(name)
      name = name.to_s.strip.delete_suffix('.').presence&.singularize
      name << '.' if (1..2).cover?(name&.size)
      name&.downcase || DEFAULT_LEVEL_NAME
    end

    # Reduce a hierarchy of numbering levels to a single value.
    #
    # @param [Hash] levels
    #
    # @return [Float]
    #
    #--
    # noinspection RubyUnusedLocalVariable
    #++
    def number_value(levels)
      factor = nil
      levels.reduce(0.0) do |result, type_entry|
        _type, entry = type_entry
        factor = factor ? (factor * 10.0) : 1.0
        (value = entry&.dig(:min)) ? (result += value / factor) : result
      end
    end

    # Reduce a hierarchy of numbering levels to a pair of single values.
    #
    # @param [Hash] levels
    #
    # @return [(Float,Float)]         Min and max level numbers.
    #
    def number_range(levels)
      r_min = r_max = 0.0
      factor = nil
      levels.values.each do |entry|
        factor = factor ? (factor * 10.0) : 1.0
        v_min, v_max = entry&.values_at(:min, :max)
        r_min += v_min / factor if v_min
        r_max += v_max / factor if (v_max ||= v_min)
      end
      return r_min, r_max
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Item title.
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [String, nil]
    #
    def title(rec)
      rec&.dc_title&.strip&.presence
    end

    # Item title ID.
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [String, nil]
    #
    def title_id(rec)
      rec&.emma_titleId&.strip&.presence
    end

    # Item repository.
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [String, nil]
    #
    def repository(rec)
      rec&.emma_repository&.strip&.presence
    end

    # Item repository record ID.
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [String, nil]
    #
    def repo_id(rec)
      rec&.emma_repositoryRecordId&.strip&.presence
    end

    # Item format.
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [String, nil]
    #
    def format(rec)
      rec&.dc_format&.strip&.presence
    end

    # Item description.
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [String, nil]
    #
    def description(rec)
      rec&.dc_description&.strip&.presence
    end

    # Item numbering extracted from #description for HathiTrust items, or from
    # the repository record ID for selected Internet Archive items.
    #
    # The result allows for a hierarchy of parts, e.g. "vol. 2 pt. 7-12" would
    # result in { 'v' => 2..2, 'p' => 7..12 }
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [Search::Record::TitleRecord::Number, nil]
    #
    # == Implementation Notes
    # * Only HathiTrust items consistently use the description field to hold
    #   the volume/chapter/number of the item.
    #
    # * The heuristic for Internet Archive items is pretty much guesswork.  The
    #   digits in the identifier following the leading term appear to be "0000"
    #   for standalone items; in items where the number appears to represent a
    #   volume, it always starts with a zero, e.g.: "0001", "0018", etc.
    #
    def item_number(rec)
      # noinspection RubyCaseWithoutElseBlockInspection
      value =
        case repository(rec)&.to_sym
          when :internetArchive
            positive(repo_id(rec)&.sub(/^[a-z].*?[a-z_.]0(\d\d\d).*$/i, '\1'))
          when :hathiTrust
            description(rec)
        end
      value &&= Search::Record::TitleRecord::Number.new(value)
      value if (1...1000).cover?(value&.number_value)
    end

    # Item date extracted from description, title or :dcterms_copyrightDate.
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [String, nil]
    #
    def item_date(rec)
      date = description(rec)
      date = nil unless date&.match?(YEAR_PATTERN)
      date = nil if date&.match?(LEADING_ITEM_NUMBER)
      date &&= (Date.parse(date) rescue nil)
      if date
        $stderr.puts "--------------- Date   | date = #{date.inspect}"
        date.to_s.delete_suffix('-01').delete_suffix('-01')
      else
        $stderr.puts "--------------- Date   | copyright = #{rec&.dcterms_dateCopyright.inspect}"
        rec&.dcterms_dateCopyright&.match(YEAR_PATTERN) && $1
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # match_fields
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    #
    # @return [Hash{Symbol=>*}]
    #
    def match_fields(rec)
      extract_fields(rec, *MATCH_FIELDS)
    end

    # sort_fields
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    #
    # @return [Hash{Symbol=>*}]
    #
    def sort_fields(rec)
      extract_fields(rec, *SORT_FIELDS)
    end

    # sort_keys
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    #
    # @return [Array]
    #
    def sort_keys(rec)
      # noinspection RubyMismatchedReturnType
      sort_fields(rec).values.flat_map do |v|
        v.try(:number_range) || v || 0
      end
    end

    # extract_fields
    #
    # @param [Search::Record::MetadataRecord, Hash, *] rec
    # @param [Array<Symbol,Array<Symbol>>]             fields
    #
    # @return [Hash{Symbol=>*}]
    #
    def extract_fields(rec, *fields)
      fields = fields.flatten
      fields.compact!
      fields.map!(&:to_sym)
      case rec
        when Hash then fields.map! { |f| [f, (rec[f] || rec[f.to_s])] }
        else           fields.map! { |f| [f, (rec.try(f) || try(f, rec))] }
      end
      fields.to_h
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  include Methods

  # Item numbering extracted from #description.
  #
  # The result allows for a hierarchy of parts, e.g. "vol. 2 pt. 6-18" would
  # result in:
  #
  #   { 'v' => { name: 'vol.', min: 2, max: 2 },
  #     'p' => { name: 'pt.',  min: 6, max: 18 } }
  #
  class Number

    include Emma::Common
    include Emma::Unicode

    include Search::Record::TitleRecord::Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A single numbering level entry.
    #
    class Level < Hash

      include Search::Record::TitleRecord::Methods

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Initialize a new level entry.
      #
      # @param [Hash] opt             Passed to #update!
      #
      def initialize(**opt)
        update!(**opt)
      end

      # Update :min/:max values if appropriate; set :name if missing.
      #
      # @param [String]  name
      # @param [Integer] min_val
      # @param [Integer] max_val
      # @param [String]  range
      #
      # @return [self]
      #
      def update!(name: nil, min_val: nil, max_val: nil, range: nil)
        # Clean leading zeros from distinct digit sequences.
        range = range&.gsub(/(?<=^|\W)0+(\d+)(?=\W|$)/, '\1')
        range = nil if range == self[:range]
        name  = number_name(name)
        name  = nil if name == self[:name]

        min, max = values_at(:min, :max)
        rng_min, rng_max = range&.split(/[^\d]+/)&.map(&:to_i)&.minmax
        min_val ||= rng_min || min || 0
        max_val ||= rng_max || max || min_val

        self[:name]  = name    if name
        self[:min]   = min_val if (new_min = min.nil? || (min_val < min))
        self[:max]   = max_val if (new_max = max.nil? || (max_val > max))
        self[:range] = nil     if new_min || new_max || range
        self[:range] ||= range || [min_val, max_val].uniq.join('-')
        self
      end

      # =======================================================================
      # :section: Object overrides
      # =======================================================================

      public

      def to_s
        values_at(:name, :range).join(' ')
      end

    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Levels of numbering extracted from the item.
    #
    # @return [Hash{String=>Level}]
    #
    attr_reader :level

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Item numbering extracted from #description or a direct level number.
    #
    # The result allows for a hierarchy of parts, e.g. "vol. 2 pt. 7-12" would
    # result in { 'v' => 2..2, 'p' => 7..12 }
    #
    # @param [String, Integer] term
    #
    def initialize(term)
      @level = {}
      # noinspection RubyMismatchedParameterType
      if term.is_a?(Integer)
        name, type   = name_type
        @level[type] = Level.new(name: name, min_val: term)
      elsif !(term = term.strip).match?(YEAR_PATTERN)
        leader = '---' # TODO: remove
        term.scan(NUMBER_PATTERN) do |match|
          name, range = match
          name, type  = name_type(name)
          next if range.remove!(/[^\d]+$/).blank?
          @level[type]&.update!(name: name, range: range)
          @level[type] ||= Level.new(name: name, range: range)
          $stderr.puts "------------#{leader} Number | text = #{match.join(' ').inspect} | name = #{name.inspect} | type = #{type.inspect} | range = #{range.inspect} | @level = #{@level.inspect} | number_value = #{number_value.inspect} | number_range = #{number_range.inspect}"
          leader = '   ' # TODO: remove
        end
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Make the level name and type.
    #
    # @param [String, nil] value      @see #number_name
    #
    # @return [(String,String)]       Normalized name and entry type.
    #
    def name_type(value = nil)
      name = number_name(value)
      return name, name[0]
    end

    # =========================================================================
    # :section: Search::Record::TitleRecord::Methods overrides
    # =========================================================================

    public

    # Reduce a hierarchy of numbering levels to a single value.
    #
    # @param [Hash, nil] levels       Default: `#level`.
    #
    # @return [Float, Integer]
    #
    def number_value(levels = nil)
      super(levels || @level)
    end

    # Reduce a hierarchy of numbering levels to a pair of single values.
    #
    # @param [Hash, nil] levels       Default: `#level`.
    #
    # @return [(Float,Float)]         Min and max level numbers.
    #
    def number_range(levels = nil)
      super(levels || @level)
    end

    # =========================================================================
    # :section: Object overrides
    # =========================================================================

    public

    def to_s
      @level.values.join(', ')
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Array<Search::Record::MetadataRecord>, Search::Record::MetadataRecord, nil] src
  # @param [Hash, nil] opt
  #
  def initialize(src, opt = nil)
    opt ||= {}
    super(nil, **opt)
    initialize_attributes
    $stderr.puts '------------ TitleRecord ------------' # TODO: remove
    Array.wrap(src).each { |rec| add(rec, false) }.presence and sort!
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Include another search result record.
  #
  # @param [Search::Record::MetadataRecord] rec
  # @param [Boolean, nil]                   sort
  #
  # @return [Array<Search::Record::MetadataRecord>]   New #records value.
  # @return [nil]                                     If *rec* not added.
  #
  def add(rec, sort = true)
    if (mismatches = problems(rec)).present?
      Log.warn { "#{self.class}##{__method__}: %s" % mismatches.join('; ') }
    else
      $stderr.puts "                #{rec.emma_titleId} | #{rec.emma_recordId} | #{rec.dc_title.inspect} | #{rec.normalized_title.inspect}" # TODO: remove
      self.records << rec.deep_dup
      sort ? sort! : records
    end
  end

=begin
  # Indicate whether *rec* is eligible for inclusion in the instance.
  #
  # @param [Search::Record::MetadataRecord] rec
  #
  def can_add?(rec)
    return false unless rec.is_a?(RECORD_CLASS)
    return true  unless exemplar.present?
    rec_fields = match_fields(rec)
    match_fields.all? { |f, required| rec_fields[f] == required }
  end
=end

  # Produce a list of field mismatches which prevent *rec* from being eligible
  # for inclusion in the instance.
  #
  # @param [Search::Record::MetadataRecord, *] rec
  #
  # @return [Array<String>]           If empty, *rec* can be included.
  #
  def problems(rec)
    return ["record is not a #{RECORD_CLASS}"] unless rec.is_a?(RECORD_CLASS)
    return []                                  unless exemplar.present?
    rec_fields = match_fields(rec)
    match_fields.map { |field, required_value|
      next if (rec_value = rec_fields[field]) == required_value
      "#{field}: #{rec_value.inspect} != #{required_value.inspect}"
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Re-organize :records so that they are in the proper order.
  #
  # @return [Array<Search::Record::MetadataRecord>]
  #
  def sort!
    records.sort_by! { |rec| sort_keys(rec) }
  end

  # The record element used as the source of bibliographic metadata.
  #
  # @return [Search::Record::MetadataRecord, nil]
  #
  def exemplar
    records.first
  end

  # ===========================================================================
  # :section: Search::Record::TitleRecord::Methods overrides
  # ===========================================================================

  public

  def title(rec = nil)
    super(rec || exemplar)
  end

  def title_id(rec = nil)
    super(rec || exemplar)
  end

  def repository(rec = nil)
    super(rec || exemplar)
  end

  def repo_id(rec = nil)
    super(rec || exemplar)
  end

  def format(rec = nil)
    super(rec || exemplar)
  end

  def description(rec = nil)
    super(rec || exemplar)
  end

  def item_number(rec = nil)
    super(rec || exemplar)
  end

  def item_date(rec = nil)
    super(rec || exemplar)
  end

  # ===========================================================================
  # :section: Search::Record::TitleRecord::Methods overrides
  # ===========================================================================

  public

  def match_fields(rec = nil)
    rec and super(rec) or @match_fields ||= super(exemplar)
  end

  def sort_fields(rec = nil)
    rec and super(rec) or @sort_fields ||= super(exemplar)
  end

  def sort_keys(rec = nil)
    super(rec || exemplar)
  end

end

__loading_end(__FILE__)
