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

  include Search::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  RECORD_CLASS = Search::Record::MetadataRecord

  schema do
    has_many :records, RECORD_CLASS
  end

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

    MATCH_FIELDS = %i[emma_titleId emma_repository dc_title].freeze

    SORT_FIELDS = %i[title repository version format].freeze

    # Patterns where, if matching a substring, $1 is the version level name.
    #
    # @type [Array<Regexp>]
    #
    NAME_PATTERNS = [
      /^([[:alpha:]]+)\.\s*(?=\d)/,   # E.g. oclc:5245282
      /^([[:alpha:].]+)(?=\d)/,       # E.g. oclc:37933152
      /^(volumes?|vols?\.?|v\.?)\s*/i
    ].deep_freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Reduce a hierarchy of versioning numbers to a single value.
    #
    # @param [Hash] levels
    #
    # @return [Float, Integer]
    #
    #--
    # noinspection RubyUnusedLocalVariable
    #++
    def number(levels)
      factor = nil
      levels.reduce(0) do |result, type_entry|
        _type, entry = type_entry
        factor = factor ? (factor * 10) : 1
        (value = entry&.dig(:min)) ? (result += value / factor) : result
      end
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

    # Item version extracted from #description for HathiTrust items, or from
    # the repository record ID for selected Internet Archive items.
    #
    # The result allows for a hierarchy of parts, e.g. "vol. 2 pt. 7-12" would
    # result in { 'v' => 2..2, 'p' => 7..12 }
    #
    # @param [Search::Record::MetadataRecord, nil] rec
    #
    # @return [Search::Record::TitleRecord::Version, nil]
    #
    # == Implementation Notes
    # * Only HathiTrust items consistently use the description field to hold
    #   the version/chapter/number of the item.
    #
    # * The heuristic for Internet Archive items is pretty much guesswork.  The
    #   digits in the identifier following the leading term appear to be "0000"
    #   for standalone items; in items where the number appears to represent a
    #   volume, it always starts with a zero, e.g.: "0001", "0018", etc.
    #
    def version(rec)
      case rec&.emma_repository&.to_sym
        when :internetArchive
          v = rec&.emma_repositoryRecordId&.presence
          v = v&.sub(/^[a-z].*?[a-z_.](0\d\d\d).*$/i, '\1')
          v = positive(v)
        when :hathiTrust
          v = description(rec)
        else
          v = description(rec)
      end
      Search::Record::TitleRecord::Version.new(v) if v.present?
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
      extract_fields(MATCH_FIELDS, rec)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # sort_fields
    #
    # @param [Search::Record::MetadataRecord, Hash, nil] rec
    #
    # @return [Hash{Symbol=>*}]
    #
    def sort_fields(rec)
      extract_fields(SORT_FIELDS, rec)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # extract_fields
    #
    # @param [Array<Symbol>]                           fields
    # @param [Search::Record::MetadataRecord, Hash, *] rec
    #
    # @return [Hash{Symbol=>*}]
    #
    def extract_fields(fields, rec)
      case rec
        when Hash then fields.map { |f| [f, (rec[f] || rec[f.to_s])] }.to_h
        else           fields.map { |f| [f, (rec.try(f) || try(f, rec))] }.to_h
      end
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

  # Item version extracted from #description.
  #
  # The result allows for a hierarchy of parts, e.g. "vol. 2 pt. 6-18" would
  # result in:
  #
  #   { 'v' => { name: 'vol.', min: 2, max: 2 },
  #     'p' => { name: 'pt.',  min: 6, max: 18 } }
  #
  # @see Search::Record::TitleRecord#sort!
  #
  class Version

    include Emma::Common
    include Emma::Unicode

    include Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A single version level entry.
    #
    class Level < Hash

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Initialize a new level entry.
      #
      # @param [String, nil]  name
      # @param [Integer, nil] min_val
      # @param [Integer, nil] max_val
      #
      def initialize(name = nil, min_val = nil, max_val = nil)
        max_val ||= min_val
        self[:name] = name&.dup
        self[:min]  = min_val
        self[:max]  = max_val
      end

      # Update :min/:max values if appropriate; set :name if missing.
      #
      # @param [String, nil]  name
      # @param [Integer, nil] min_val
      # @param [Integer, nil] max_val
      #
      # @return [self]
      #
      def update!(name = nil, min_val = nil, max_val = nil)
        max_val ||= min_val
        self[:name] = name&.dup if self[:name].nil? && name
        self[:min]  = min_val   if self[:min].nil?  || (min_val < self[:min])
        self[:max]  = max_val   if self[:max].nil?  || (max_val > self[:max])
        self
      end

    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Levels of version numbering extracted from the item.
    #
    # @return [Hash{String=>Level}]
    #
    attr_reader :level

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Item version extracted from #description or a direct version number.
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
        @level[type] = Level.new(name, term)
      else
        term.strip.split(/\s*[#{EN_DASH}#{EM_DASH},-]+\s*/).each do |range|
          name, type = name_type
          range.split(/(?<=\d)\s+/).each do |part|
            next if part.blank?
            original = part.dup # TODO: remove
            NAME_PATTERNS.any? { |pattern| part.sub!(pattern, '') }
            name, type = name_type($1) if $1
            next unless (value = positive(part))
            @level[type]&.update!(name, value)
            @level[type] ||= Level.new(name, value)
            $stderr.puts "------ Version | part(before) = #{original.inspect} | part(after) = #{part.inspect} | $1 = #{$1.inspect} | name = #{name.inspect} | type = #{type.inspect} | value = #{value.inspect} | @level = #{@level.inspect} | number = #{number.inspect}"
          end
        end
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Make the level name and type.
    #
    # @param [String, nil] value      Default: `#DEFAULT_LEVEL_NAME`.
    #
    # @return [(String,String)]       Normalized name and entry type.
    #
    def name_type(value = nil)
      name    = value.presence&.singularize
      name[0] = name[0].downcase if name
      name  ||= DEFAULT_LEVEL_NAME
      return name, name[0]
    end

    # =========================================================================
    # :section: Search::Record::TitleRecord::Methods overrides
    # =========================================================================

    public

    # Reduce a hierarchy of versioning numbers to a single value.
    #
    # @param [Hash, nil] levels       Default: `#level`.
    #
    # @return [Float, Integer]
    #
    def number(levels = nil)
      super(levels || @level)
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
      self.records << rec.deep_dup
      # noinspection RubyMismatchedReturnType
      false?(sort) ? records : sort!
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
  # @see #version_number
  #
  def sort!
    records.sort_by! do |rec|
      sort_fields(rec).values.map do |v|
        v.try(:number) || v || 0
      end
    end
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

  def format(rec = nil)
    super(rec || exemplar)
  end

  def description(rec = nil)
    super(rec || exemplar)
  end

  def version(rec = nil)
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

end

__loading_end(__FILE__)
