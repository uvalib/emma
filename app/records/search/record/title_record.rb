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

  include Search::Shared::AggregateMethods
  include Search::Shared::CreatorMethods
  include Search::Shared::DateMethods
  include Search::Shared::IdentifierMethods
  include Search::Shared::LinkMethods
  include Search::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  BASE_ELEMENT = Search::Record::MetadataRecord

  schema do
    has_many :records, BASE_ELEMENT
  end

  delegate_missing_to :exemplar

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

    # Fields whose values are identical across all #records.
    #
    # @type [Array<Symbol>]
    #
    MATCH_FIELDS = GROUPING_LEVELS.flatten.freeze

    # Fields whose values are used as keys to sort #records.
    #
    # @type [Array<Symbol>]
    #
    SORT_FIELDS = %i[
      dc_title
      emma_repository
      item_number
      dc_format
      emma_collection
      item_date
      dcterms_dateAccepted
      emma_repositoryRecordId
    ].freeze

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
    # If `match(YEAR_PATTERN)` succeeds, the year will be $2 or $3.
    #
    # @type [Regexp]
    #
    YEAR_PATTERN = /^(\s*(\d{4})|[^\d]*\W(\d{4}))(?=\W|$)/.freeze

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
    # @param [Number, Hash{Any=>Number::Level}, nil] item
    #
    # @return [Float]
    #
    #--
    # noinspection RubyUnusedLocalVariable
    #++
    def number_value(item)
      return item.number_value if item.respond_to?(:number_value)
      factor = nil
      # noinspection RailsParamDefResolve
      levels = item.try(:level) || item || {}
      levels.reduce(0.0) do |result, type_entry|
        _type, entry = type_entry
        factor = factor ? (factor * 10.0) : 1.0
        (value = entry&.dig(:min)) ? (result + (value / factor)) : result
      end
    end

    # Reduce a hierarchy of numbering levels to a pair of single values.
    #
    # @param [Number, Hash{Any=>Number::Level}] item
    #
    # @return [Array<(Float,Float)>]  Min and max level numbers.
    #
    def number_range(item)
      return item.number_range if item.respond_to?(:number_range)
      r_min = r_max = 0.0
      factor  = nil
      # noinspection RailsParamDefResolve
      entries = item.try(:level) || item
      entries = entries.is_a?(Hash) ? entries.values : Array.wrap(entries)
      entries.each do |entry|
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
    # === Implementation Notes
    # * Only HathiTrust items consistently use the description field to hold
    #   the volume/chapter/number of the item.
    #
    # * The heuristic for Internet Archive items is pretty much guesswork.  The
    #   digits in the identifier following the leading term appear to be "0000"
    #   for standalone items; in items where the number appears to represent a
    #   volume, it always starts with a zero, e.g.: "0001", "0018", etc.
    #
    def item_number(rec)
      return if rec.blank?
      value = rec.try(:bib_seriesPosition).presence
      value ||=
        case repository(rec)&.to_sym
          when :internetArchive, :ace
            positive(repo_id(rec)&.sub(/^[a-z].*?[a-z_.]0(\d\d\d).*$/i, '\1'))
        end
      value &&= Number.new(value)
      value if value && (1...1000).cover?(value.number_value)
    end

    # Item date extracted from description, title or :dcterms_dateCopyright.
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [String, nil]
    #
    def item_date(rec)
      return if rec.blank?
      year = get_year(rec.dcterms_dateCopyright) and return year
      year = get_year(rec.emma_publicationDate)  and return year
      date = description(rec)
      get_year(date) unless date&.match?(LEADING_ITEM_NUMBER)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Attempt to extract a year from the given string.
    #
    # @param [String, nil] value
    #
    # @return [String, nil]
    #
    def get_year(value)
      value.to_s.presence&.match(YEAR_PATTERN) && ($2 || $3)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Fields values used to determine whether *rec* can be included.
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    #
    # @return [Hash{Symbol=>Any}]
    #
    def match_fields(rec)
      comparable_fields(rec, MATCH_FIELDS)
    end

    # Field values used as the basis of #sort_keys.
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    #
    # @return [Hash{Symbol=>Any}]
    #
    def sort_fields(rec)
      extract_fields(rec, SORT_FIELDS)
    end

    # The values for *rec* for use with Enumerable#sort_by.
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    # @param [Boolean]                                   exact
    #
    # @return [Array]
    #
    def sort_keys(rec, exact = true)
      sort_fields(rec).values.map { |v| sort_key_value(v, exact) }
    end

    # extract_fields
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    # @param [Array<Symbol>]                             fields
    #
    # @return [Hash{Symbol=>Any}]
    #
    def extract_fields(rec, fields)
      return {} if rec.blank?
      fields = fields.flatten
      fields.compact!
      # noinspection RubyMismatchedArgumentType
      fields.map! { |f| [f.to_sym, field_value(rec, f)] }.to_h
    end

    # Fields with values normalized for comparison.
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    # @param [Array<Symbol>]                             fields
    #
    # @return [Hash{Symbol=>Any}]
    #
    def comparable_fields(rec, fields)
      extract_fields(rec, fields).map { |field, value|
        [field, make_comparable(value, field)]
      }.to_h
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Transform a value into one whose elements are prepared for comparison
    # with a similar value.
    #
    # @param [Hash, Array, String, Any, nil] value
    # @param [Symbol, nil]                   field
    #
    # @return [Hash, Array, String, Any]  Same type as original type of *value*
    #
    def make_comparable(value, field = nil)
      if Log.debug?
        case value
          when Number, Model, Hash
            Log.debug { "#{__method__}: ignoring field = #{field.inspect}" }
        end
      end
      id_fld = field && IDENTIFIER_FIELDS.include?(field)
      case value
        when Number
          value.number_value
        when Model
          make_comparable(value.fields)
        when Hash
          # noinspection RubyMismatchedReturnType
          value.map { |k, v|
            v = make_comparable(v, k)
            [k, v] if v.present?
          }.compact.sort_by! { |kv| kv&.first || '' }.to_h
        when Array
          if id_fld
            value.compact_blank.sort_by! { |v| identifier_sort_key(v) }
          else
            value.map { |v| make_comparable(v, field) }.compact_blank!.sort!
          end
        else
          # noinspection RubyMismatchedReturnType
          id_fld ? value : value.to_s.downcase.gsub(/[[:punct:]]/, ' ').squish
      end
    end

    # Group identifiers of the same prefix in descending order of length
    # (favoring ISBN-13 over ISBN-10).
    #
    # @param [String, nil] id
    #
    # @return [Array<(String, Integer, String)>]
    #
    def identifier_sort_key(id)
      id     = PublicationIdentifier.cast(id, invalid: true)
      value  = id.to_s
      length = -value.size
      prefix = id&.prefix || ''
      [prefix, length, value]
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Normalize a value for use as a sort key value.
    #
    # @param [Any, nil] item
    # @param [Boolean] exact
    #
    # @return [Any]
    #
    def sort_key_value(item, exact = true)
      if item.is_a?(Array)
        item.map { |v| sort_key_value(v, exact) }.join(' ')
      elsif item.is_a?(String)
        item.strip
      elsif item.respond_to?(:to_datetime)
        item.to_datetime.to_s
      elsif item.respond_to?(:number_value)
        item.number_value
      elsif exact
        item || 0
      else
        item.to_s
      end
    end

    # field_value
    #
    # @param [Search::Record::MetadataRecord, Hash] rec
    # @param [Symbol, String]                       field
    #
    # @return [Any, nil]
    #
    def field_value(rec, field)
      if field.blank?
        # Log.warn { "#{__method__}: invalid field: #{field.inspect}" }
      elsif rec.respond_to?(:[])
        rec[field.to_sym] || rec[field.to_s]
      elsif rec.respond_to?(field)
        rec.send(field)
      elsif respond_to?(field)
        send(field, rec)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @private
    IDENTIFIER_FIELDS = Api::Shared::IdentifierMethods::IDENTIFIER_FIELDS

    # Combined information from the values of the given fields of all of the
    # records.
    #
    # @param [Array<Search::Record::MetadataRecord>] recs
    # @param [Array<Symbol>]                         fields
    #
    # @return [Hash{Symbol=>Any}]
    #
    def field_union(recs, fields)
      array  = fields.map { |k| [k, false] }.to_h
      result = fields.map { |k| [k, []] }.to_h
      recs.each do |rec|
        fields.each do |field|
          next unless (value = field_value(rec, field))
          array[field] ||= value.is_a?(Array)
          result[field].concat(Array.wrap(value))
        end
      end
      result.map { |field, value|
        next if value.blank?
        if value.many?
          if IDENTIFIER_FIELDS.include?(field)
            value.sort_by! { |v| identifier_sort_key(v) }.uniq!
          else
            value.sort_by! { |v| make_comparable(v, field) }
            value.uniq!    { |v| make_comparable(v, field) }
          end
        end
        value = value.join(' / ') unless array[field]
        [field, value]
      }.compact.to_h
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
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

    include Comparable

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

      include Comparable

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
      # @param [String]        name
      # @param [Integer]       min_val
      # @param [Integer]       max_val
      # @param [String, Range] range
      #
      # @return [self]
      #
      def update!(name: nil, min_val: nil, max_val: nil, range: nil)
        rng_min, rng_max =
          if range.is_a?(String)
            # Clean leading zeros from distinct digit sequences.
            range = range.gsub(/(?<=^|\W)0+(\d+)(?=\W|$)/, '\1')
            range.split(/[^\d]+/).map(&:to_i).minmax
          elsif range.is_a?(Range)
            Log.warn {
              "TitleRecord::Number: not an integer range: #{range.inspect}"
            } unless range.min.is_a?(Integer)
            range.minmax.map(&:to_i)
          end
        min_val ||= rng_min || self[:min] || 0
        max_val ||= rng_max || self[:max] || min_val
        range = [min_val, max_val].uniq.join('-') unless range.is_a?(String)
        name  = number_name(name)

        self[:name]  = name    unless name == self[:name]
        self[:min]   = min_val if self[:min].nil? || (min_val < self[:min])
        self[:max]   = max_val if self[:max].nil? || (max_val > self[:max])
        self[:range] = range   unless range == self[:range]
        self
      end

      # minimum
      #
      # @return [Integer]
      #
      def minimum
        self[:min]
      end

      # maximum
      #
      # @return [Integer]
      #
      def maximum
        self[:max]
      end

      # range
      #
      # @return [String]
      #
      def range
        self[:range]
      end

      # =======================================================================
      # :section: Object overrides
      # =======================================================================

      public

      def to_s
        values_at(:name, :range).join(' ')
      end

      # =======================================================================
      # :section: Hash overrides
      # =======================================================================

      public

      # Value needed to make instances usable from Enumerable#group_by.
      #
      # @return [Integer]
      #
      def hash
        range.hash
      end

      # Operator needed to make instances usable from Enumerable#group_by.
      #
      # @param [*] other
      #
      def eql?(other)
        self == other
      end

      # =======================================================================
      # :section: Comparable
      # =======================================================================

      public

      # Comparison operator required by the Comparable mixin.
      #
      # @param [*] other
      #
      # @return [Integer]   -1 if self is later, 1 if self is earlier
      #
      def <=>(other)
        other_min = other.try(:minimum) || other.try(:[], :min) || 0
        other_max = other.try(:maximum) || other.try(:[], :max) || other_min
        (minimum <=> other_min).nonzero? || (maximum <=> other_max)
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
    # @param [String, Integer, Hash, nil] term
    #
    #--
    # noinspection RubyMismatchedArgumentType
    #++
    def initialize(term = nil)
      @level = {}
      case term
        when Integer
          add_level(nil, term)
        when String
          unless (term = term.strip).match?(YEAR_PATTERN)
            term.scan(NUMBER_PATTERN) do |match|
              name, range = match
              next unless range.remove!(/[^\d]+$/).present?
              add_level(name, range: range)
            end
          end
        when Hash
          term.each_pair { |name, value| add_level(name, value) }
        else
          Log.warn { "TitleRecord::Number: #{term.class} unexpected" } if term
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Add to #level.
    #
    # @param [String, nil] name
    # @param [*]           value
    # @param [Hash]        opt        Passed to Level initializer.
    #
    # @return [void]
    #
    def add_level(name, value = nil, **opt)
      name, type = name_type(name)
      opt[:name]    = name  if name
      opt[:min_val] = value if value
      @level[type]&.update!(**opt)
      @level[type] ||= Level.new(**opt)
    end

    # Make the level name and type.
    #
    # @param [String, nil] value      @see #number_name
    #
    # @return [Array<(String,String)>]  Normalized name and entry type.
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
    # @param [Number, Hash, nil] item   Default: `#level`.
    #
    # @return [Float]
    #
    def number_value(item = nil)
      if item.nil? || (item == self)
        @number_value ||= super(@level)
      else
        # noinspection RailsParamDefResolve, RubyMismatchedArgumentType
        item.try(__method__) || super(item.try(:level) || item)
      end
    end

    # Reduce a hierarchy of numbering levels to a pair of single values.
    #
    # @param [Number, Hash, nil] item   Default: `#level`.
    #
    # @return [Array<(Float,Float)>]  Min and max level numbers.
    #
    def number_range(item = nil)
      if item.nil? || (item == self)
        @number_range ||= super(@level)
      else
        # noinspection RailsParamDefResolve, RubyMismatchedArgumentType
        item.try(__method__) || super(item.try(:level) || item)
      end
    end

    # =========================================================================
    # :section: Object overrides
    # =========================================================================

    public

    def to_s
      @level.values.join(', ')
    end

    # Value needed to make instances usable from Enumerable#group_by.
    #
    # @return [Integer]
    #
    def hash
      number_value.hash
    end

    # Operator needed to make instances usable from Enumerable#group_by.
    #
    # @param [*] other
    #
    def eql?(other)
      self == other
    end

    # =========================================================================
    # :section: Comparable
    # =========================================================================

    public

    # Comparison operator required by the Comparable mixin.
    #
    # @param [*] other
    #
    # @return [Integer]   -1 if self is later, 1 if self is earlier
    #
    def <=>(other)
      other = Number.new(other) if other && !other.is_a?(Number)
      other_min, other_max = other&.number_range || [0, 0]
      self_min,  self_max  = number_range
      (self_min <=> other_min)&.nonzero? || (self_max <=> other_max)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether only canonical records will be used.
  #
  # @return [Boolean]
  #
  attr_reader :canonical

  # An artificial record element representing the metadata common to all
  # constituent file-level records.
  #
  # @return [Search::Record::MetadataRecord]
  #
  attr_reader :exemplar

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
    opt = opt&.dup || {}
    @canonical = opt.delete(:canonical).present?
    # noinspection RubyMismatchedVariableType
    @hierarchy = @exemplar = nil
    super(nil, **opt)
    initialize_attributes
    self.records = copy_records(src)
    @exemplar    = make_exemplar
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Copy usable record(s) from the source.
  #
  # @param [Array<Search::Record::MetadataRecord>, Search::Record::MetadataRecord, nil] src
  #
  # @return [Array<Search::Record::MetadataRecord>]
  #
  # === Implementation Notes
  # Because #problems uses #exemplar to check validity, it is (temporarily) set
  # here as the copy of the first valid record encountered.
  #
  def copy_records(src)
    Array.wrap(src).map { |rec|
      if rec.blank?
        # Log.debug { "#{self.class}: nil record" }
      elsif @canonical && !rec.canonical?
        Log.info { "#{self.class}: skipping #{rec}" }
      elsif (mismatches = problems(rec)).present?
        Log.warn { "#{self.class}: %s" % mismatches.join('; ') }
      else
        copy_record(rec).tap { |r| @exemplar ||= r }
      end
    }.compact.tap { |recs| sort_records!(recs) if recs.many? }
  end

  # Sort records.
  #
  # If #sort_keys results in a set of value which cause Array#sort_by! to
  # fail then re-attempt with a less exact set of values.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
  #
  # @return [Array<Search::Record::MetadataRecord>]
  #
  def sort_records!(recs)
    recs.sort_by! { |rec| sort_keys(rec) }
  rescue
    recs.sort_by! { |rec| sort_keys(rec, false) }
  end

  # Copy the record, adding an item_number if appropriate.
  #
  # @param [Search::Record::MetadataRecord] rec
  #
  # @return [Search::Record::MetadataRecord]
  #
  def copy_record(rec)
    rec.dup.tap do |result|
      set_item_number(result, :bib_seriesPosition)
      copy_identifier(result, :dc_identifier)
      copy_identifier(result, :dc_relation)
    end
  end

  # Generate a series position number if one isn't already present.
  #
  # @param [Search::Record::MetadataRecord] rec
  # @param [Symbol]                         field
  #
  # @return [void]
  #
  def set_item_number(rec, field)
    return if rec.try(field).present?
    value = item_number(rec)&.to_s
    rec.try("#{field}=", value)
  end

  # Re-arrange the contents of the identifier field .
  #
  # @param [Search::Record::MetadataRecord] rec
  # @param [Symbol]                         field
  #
  # @return [void]
  #
  # @see #identifier_sort_key
  #
  def copy_identifier(rec, field)
    value = rec.try(field)
    return unless value.try(:many?)
    value = value.sort_by { |id| identifier_sort_key(id) }
    rec.try("#{field}=", value)
  end

  # Produce a list of field mismatches which prevent *rec* from being eligible
  # for inclusion in the instance.
  #
  # @param [Search::Record::MetadataRecord] rec
  #
  # @return [Array<String>]           If empty, *rec* can be included.
  #
  # === Implementation Notes
  # On its first invocation, #exemplar will be nil because it has not yet been
  # assigned in #copy_records.
  #
  def problems(rec)
    return ["record is not a #{BASE_ELEMENT}"] unless rec.is_a?(BASE_ELEMENT)
    return []                                  unless exemplar.present?
    rec_fields = match_fields(rec)
    match_fields(exemplar).map { |field, required_value|
      next if required_value.blank? || (rec_value = rec_fields[field]).blank?
      next if rec_value == required_value
      "#{field}: #{rec_value.inspect} != #{required_value.inspect}"
    }.compact
  end

  # Create the exemplar as a copy of the first record, with #UNION_FIELDS
  # replaced by combined information from all of the records.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs   Default: #records.
  #
  # @return [Search::Record::MetadataRecord]
  #
  def make_exemplar(recs = nil)
    recs   = recs&.compact || records || []
    result = recs.first&.dup || BASE_ELEMENT.new
    if recs.many?
      title_field_union(recs).each_pair do |union_field, union_value|
        result.try("#{union_field}=", union_value)
      end
    end
    if recs.present?
      file_only_fields  = title_field_exclusive(recs)
      title_only_fields = EXCLUSIVE_FIELDS - file_only_fields
      file_only_fields.each { |f| result.try("#{f}=", nil) }
      title_only_fields.each { |f| recs.each { |r| r.try("#{f}=", nil) } }
    end
    result
  end

  # Record fields honored by #title_field_union.
  #
  # These values show up in the exemplar as a conjunction of the unique record
  # value(s).
  #
  # @type [Array<Symbol>]
  #
  UNION_FIELDS = %i[
    dc_creator
    dc_description
    dc_identifier
    dc_related
    dc_rights
    dcterms_dateCopyright
    emma_titleId
  ].freeze

  # Combined information from the #UNION_FIELDS values all of the records.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
  #
  # @return [Hash{Symbol=>Any}]
  #
  def title_field_union(recs = records.to_a)
    field_union(recs, UNION_FIELDS)
  end

  # Record fields honored by #title_field_exclusive.
  #
  # These fields either show up in the exemplar because they are identical in
  # all of the records *or* they show up in each individual file-level record.
  #
  # @type [Array<Symbol>]
  #
  EXCLUSIVE_FIELDS = %i[
    emma_collection
    emma_titleId
  ].freeze

  # List fields which have more than one value across all of the records.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
  #
  # @return [Array<Symbol>]
  #
  def title_field_exclusive(recs = records.to_a)
    return [] unless recs.many?
    EXCLUSIVE_FIELDS.select do |field|
      first = nil
      # noinspection RubyMismatchedReturnType
      recs.find do |rec|
        next if (value = field_value(rec, field)).blank?
        next if first.nil? && (first = make_comparable(value, field))
        first != make_comparable(value, field)
      end
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Recursively convert configuration items from String to Symbol.
  #
  # @param [Hash, Array, String, Symbol, Any] item
  #
  # @return [Hash, Array, Symbol, Any]
  #
  #--
  # === Variations
  #++
  #
  # @overload symbolize_values(string)
  #   @param [String] string
  #   @return [Symbol] String converted to symbol.
  #
  # @overload symbolize_values(non_string)
  #   @param [Hash, Array, Any] non_string
  #   @return [Hash, Array, Any] Same type, possibly a modified copy.
  #
  def self.symbolize_values(item)
    # noinspection RubyMismatchedReturnType
    case item
      when Hash   then item.transform_values { |v| symbolize_values(v) }
      when Array  then item.map { |v| symbolize_values(v) }
      when String then item.to_sym
      else             item
    end
  end

  # hierarchy_paths
  #
  # @param [Hash, Array, Any] item
  # @param [Array<Symbol>]    path
  #
  # @return [Array<Array<(Symbol,Array<Symbol,Integer>)>>]
  #
  def self.hierarchy_paths(item, path = [])
    case item
      when Hash
        item.flat_map { |level, value|
          next if level.start_with?('_') || !value.is_a?(Enumerable)
          hierarchy_paths(value, [*path, level])
        }.compact
      when Array
        item.map.with_index { |field, position| [field, [*path, position]] }
      else
        []
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  DEBUG_HIERARCHY = false

  # Hierarchical field ordering.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  FIELD_HIERARCHY =
    symbolize_values(I18n.t('emma.search.field_hierarchy')).deep_freeze

  # HIERARCHY_PATHS
  #
  # @type [Hash{Symbol=>Array<Symbol,Integer>}]
  #
  HIERARCHY_PATHS = hierarchy_paths(FIELD_HIERARCHY).to_h.deep_freeze

  # ===========================================================================
  # :section: Api::Record overrides
  # ===========================================================================

  public

  # All #records fields in hierarchical order.
  #
  # @param [Boolean] wrap             Wrap arrays (for XML rendering).
  # @param [Hash]    pairs            Additional title-level field/value pairs.
  #
  # @return [Hash{Symbol=>Hash,Array<Hash>}]
  #
  def field_hierarchy(wrap: false, **pairs)
    pairs  = pairs.presence
    result = @hierarchy ||= make_field_hierarchy
    result = result.deep_dup                      if pairs || wrap
    result[:title].merge!(pairs)                  if pairs
    wrap_array!(result, :parts, :formats, :files) if wrap
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # get_format_counts
  #
  # @return [Hash{String=>Integer}]
  #
  def get_format_counts
    result  = {}
    formats = field_hierarchy[:parts]&.flat_map { |part| part[:formats] } || []
    formats.each do |format|
      next unless (fmt = format.dig(:bibliographic, :dc_format))
      result[fmt] ||= 0
      result[fmt] += Array.wrap(format[:files]).size
    end
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # make_field_hierarchy
  #
  # @return [Hash{Symbol=>Hash,Array<Hash>}]
  #
  def make_field_hierarchy
    { title: get_title_fields, parts: get_part_fields }
      .tap { validate_title_fields if DEBUG_HIERARCHY }
  end

  # get_title_fields
  #
  # @param [Search::Record::MetadataRecord, nil] rec    Default: #exemplar
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def get_title_fields(rec = nil)
    rec = exemplar if rec.nil? || (rec == self)
    get_fields(rec, :title)
  end

  # get_part_fields
  #
  # @param [Array<Search::Record::MetadataRecord>]
  #
  # @return [Array<Hash>]
  #
  def get_part_fields(recs = records.to_a)
    recs.group_by { |rec| item_number(rec) }.map do |part, recs1|
      part = { bib_seriesPosition: part.to_s }
      fmts =
        recs1.group_by { |rec| format(rec) }.map do |format, recs2|
          format = { dc_format: format }
          files  = get_file_fields(:parts, :formats, :files, recs2)
          { bibliographic: format, files: files }
        end
      { bibliographic: part, formats: fmts }
    end
  end

  # get_file_fields
  #
  # @param [Array<Symbol,Search::Record::MetadataRecord,Array>] group
  #
  # @return [Array<Hash>]
  #
  def get_file_fields(*group)
    case group.last
      when Search::Record::MetadataRecord then Array.wrap(group.pop)
      when Array                          then group.pop
      else                                     records
    end.map { |rec| get_fields(rec, *group) }
  end

  # get_fields
  #
  # @param [Search::Record::MetadataRecord, nil] rec
  # @param [Array<Symbol>]                       group
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def get_fields(rec, *group)
    case (section = rec.presence && FIELD_HIERARCHY.dig(*group))
      when Hash
        section.transform_values { |fields|
          get_record_fields(rec, fields) if fields.is_a?(Array)
        }.compact
      when Array
        get_record_fields(rec, section)
      else
        Log.debug do
          "#{__method__}: skipping #{section.class} = #{section.inspect}"
        end if section
    end || {}
  end

  # get_record_fields
  #
  # @param [Search::Record::MetadataRecord, Hash, nil] rec
  # @param [Array<Symbol>, Symbol]                     fields
  #
  # @return [Hash]
  #
  def get_record_fields(rec, fields)
    Array.wrap(fields).map { |field|
      value = rec.try(field) || rec.try(:[], field)
      [field, value]
    }.to_h.compact
  end

  # To support XML rendering...
  #
  # @param [Hash, Any, nil] value
  # @param [Array<Symbol>]  keys
  #
  # @return [Hash, Any]               The (possibly modified) *value*.
  #
  def wrap_array!(value, *keys)
    return value unless value.is_a?(Hash)
    keys.map!(&:to_sym)
    item_key = keys.map { |k| [k, k.to_s.singularize.to_sym] }.to_h
    value.map { |k, v|
      if keys.include?(k)
        v = Array.wrap(v).map { |i| { item_key[k] => wrap_array!(i, *keys) } }
      elsif v.is_a?(Hash)
        v = wrap_array!(v, *keys)
      end
      [k, v]
    }.to_h.tap { |result| value.replace(result) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Output fields of records which do not agree with the common title fields
  # in the exemplar.
  #
  # @param [Array<Search::Record::MetadataRecord>] recs
  #
  # @return [void]
  #
  def validate_title_fields(recs = records.to_a)
    title_fields        = get_title_fields
    shared_title_values = make_comparable(title_fields)
    recs.each.with_index(1) do |rec, idx|
      rec_fields       = get_fields(rec, :title)
      rec_title_fields = make_comparable(rec_fields)
      shared_title_values.each_pair do |section, shared_values|
        rec_title_fields[section]&.each_pair do |k, v|
          next if v == shared_values[k]
          sec    = '%-15s' % "[#{section}]"
          field  = '%-20s' % "[#{k}]"
          record = "FILE #{idx} -> #{rec_fields[section][k].inspect}"
          shared = "EXEMPLAR -> #{title_fields[section][k].inspect}"
          __output "*** #{sec} | #{field} #{record} | #{shared}"
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # all_item_numbers
  #
  # @param [String, nil] separator
  #
  # @return [Array<String>]               If *separator* not given.
  # @return [ActiveSupport::SafeBuffer]   If *separator* is HTML-safe.
  # @return [String]                      If *separator* is a plain string.
  #
  def all_item_numbers(separator = nil)
    html    = separator.is_a?(ActiveSupport::SafeBuffer)
    numbers = records.map { |rec| item_number(rec) }
    numbers.compact!
    numbers.sort_by!(&:number_value)
    numbers.uniq!(&:number_range)
    numbers.map!(&:to_s)
    numbers.map! { |v| ERB::Util.h(v) } if html
    numbers = numbers.join(separator)   if separator
    numbers = numbers.html_safe         if html
    # noinspection RubyMismatchedReturnType
    numbers
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # The fields and values for this instance as a Hash.
  #
  # @param [*] item   Presence used as an indicator that individual records
  #                   should be wrapped (i.e., that the intended output format
  #                   is XML).
  #
  # @return [Hash{Symbol=>*}]
  #
  def to_h(**opt)
    wrap   = opt[:item].present?
    tree   = field_hierarchy(wrap: wrap)
    result = fields
    wrap_array!(result, :records) if wrap
    result.reverse_merge!(fields: reject_blanks(tree))
  end

end

__loading_end(__FILE__)
