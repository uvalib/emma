# app/services/lookup_service/world_cat/action/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::WorldCat::Action::Records
#
module LookupService::WorldCat::Action::Records

  include LookupService::WorldCat::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET https://worldcat.org/webservices/catalog/search/worldcat/sru
  #
  # Sometimes the service will return appropriate results when searching for an
  # ISBN but the returned record will not include any identifiers.
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @return [Lookup::WorldCat::Message::Sru]
  #
  # @see https://developer.api.oclc.org/wcv1#operations-SRU-search-sru
  #
  # @note The documentation incorrectly states that the endpoint is
  #   '/search/worldcat/sru', however this does not work.
  #
  def get_sru_records(terms, **opt)
    terms = query_terms(terms, opt)
    isbns = lccns = nil
    if terms[:ids].present?
      isbns = Array.wrap(terms.dig(:ids, :bn)).presence
      lccns = Array.wrap(terms.dig(:ids, :dn)).presence
    elsif terms.dig(:limit, :la).blank?
      # If not looking for specific items, limit results to English.
      terms[:limit] ||= LimitTerms.new
      terms[:limit].add(:lang_code, 'eng')
    end
    # noinspection RubyMismatchedArgumentType
    opt[:query] = make_query(terms)

    opt = get_parameters(__method__, **opt)

    api(:get, 'catalog/search/worldcat/sru', **opt)
    api_return(Lookup::WorldCat::Message::Sru).tap do |result|
      if terms[:ids].blank?
        # If this is a general search, remove entries for videos in order to
        # keep from overwhelming results.
        #
        # @type [Lookup::WorldCat::Record::SruRecord] record
        result.records.delete_if do |record|
          type = record&.recordData&.oclcdcs&.dc_type&.downcase
          type == 'image'
        end
      elsif isbns || lccns
        isbns &&= isbns.map { |v| "isbn:#{v}" }
        lccns &&= lccns.map { |v| "lccn:#{v}" }
        # @type [Lookup::WorldCat::Record::SruRecord] record
        result.records.each do |record|
          ids = record&.recordData&.oclcdcs&.dc_identifier
          next if lccns && lccns.include?(ids&.first)
          next if isbns && ids.present?
          record.recordData.oclcdcs.dc_identifier = [*lccns, *isbns, *ids].uniq
        end
      end
    end
  end
    .tap do |method|
      # noinspection SpellCheckingInspection
      add_api method => {
        alias: {
          limit:          :maximumRecords,
          sort:           :sortKeys,
          start:          :startRecord,
          q:              :query,
        },
        required: {
          query:          String,
        },
        optional: {
          recordSchema:   String,
          startRecord:    Integer,
          maximumRecords: Integer,  # NOTE: *not* 'maximiumRecords'
          sortKeys:       String,
          servicelevel:   String,   # Values: "full" or "default" (default).
          frbrGrouping:   String,   # Values: "off" or "on" (default).
        },
        role: :anonymous,           # Should succeed for any user.
      }
    end

  # === GET https://worldcat.org/webservices/catalog/content/(oclc_number)
  #
  # @param [String, Oclc] term        Single OCLC identifier.
  # @param [Hash]         opt
  #
  # @return [Lookup::WorldCat::Message::Oclc]
  #
  # @see https://developer.api.oclc.org/wcv1#operations-Read-read-oclcnumber
  #
  def get_oclc(term, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'catalog/content', term, **opt)
    api_return(Lookup::WorldCat::Message::Oclc)
  end
    .tap do |method|
      # noinspection SpellCheckingInspection
      add_api method => {
        optional: {
          recordSchema: String,
          servicelevel: String,     # Values: "full" or "default" (default).
        },
        role: :anonymous,           # Should succeed for any user.
      }
    end

  # === GET https://worldcat.org/webservices/catalog/content/isbn/(isbn)
  #
  # @param [String, Isbn] term        Single ISBN identifier.
  # @param [Hash]         opt
  #
  # @return [Lookup::WorldCat::Message::Isbn]
  #
  # @see https://developer.api.oclc.org/wcv1#operations-Read-read-isbn
  #
  def get_isbn(term, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'catalog/content/isbn', term, **opt)
    api_return(Lookup::WorldCat::Message::Isbn)
  end
    .tap do |method|
      # noinspection SpellCheckingInspection
      add_api method => {
        optional: {
          recordSchema: String,
          servicelevel: String,     # Values: "full" or "default" (default).
        },
        role: :anonymous,           # Should succeed for any user.
      }
    end

  # === GET https://worldcat.org/webservices/catalog/content/issn/(issn)
  #
  # @param [String, Issn] term        Single ISSN identifier.
  # @param [Hash]         opt
  #
  # @return [Lookup::WorldCat::Message::Issn]
  #
  # @see https://developer.api.oclc.org/wcv1#operations-Read-read-issn
  #
  def get_issn(term, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'catalog/content/issn', term, **opt)
    api_return(Lookup::WorldCat::Message::Issn)
  end
    .tap do |method|
      # noinspection SpellCheckingInspection
      add_api method => {
        optional: {
          recordSchema: String,
          servicelevel: String,     # Values: "full" or "default" (default).
        },
        role: :anonymous,           # Should succeed for any user.
      }
    end

  # === GET https://worldcat.org/webservices/catalog/content/sn/(lccn)
  #
  # @param [String, Lccn] term        Single LCCN identifier.
  # @param [Hash]         opt
  #
  # @return [Lookup::WorldCat::Message::Lccn]
  #
  # @see https://developer.api.oclc.org/wcv1#operations-Read-read-sn
  #
  # === Usage Notes
  # Strictly speaking, the API endpoint accepts a "Standard Number", which
  # according to https://www.loc.gov/marc/bibliographic/bd024.html might be
  # an identifier from any of the source code schemes listed in
  # https://www.loc.gov/standards/sourcelist/standard-identifier.html (where
  # LCCN is only one of the possibilities).
  #
  def get_lccn(term, **opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'catalog/content/sn', term, **opt)
    api_return(Lookup::WorldCat::Message::Lccn)
  end
    .tap do |method|
      # noinspection SpellCheckingInspection
      add_api method => {
        optional: {
          recordSchema: String,
          servicelevel: String,     # Values: "full" or "default" (default).
        },
        role: :anonymous,           # Should succeed for any user.
      }
    end

  # === GET https://worldcat.org/webservices/catalog/search/worldcat/opensearch
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @return [Lookup::WorldCat::Message::OpenSearch]
  #
  # @see https://developer.api.oclc.org/wcv1#operations-tag-OpenSearch
  #
  # @note The documentation incorrectly states that the endpoint is
  #   '/search/worldcat/opensearch', however this does not work.
  #
  def get_opensearch_records(terms, **opt)
    q_terms = query_terms(terms, opt)
    opt[:q] = make_query(q_terms)
    opt = get_parameters(__method__, **opt)
    api(:get, 'catalog/search/worldcat/opensearch', **opt)
    api_return(Lookup::WorldCat::Message::OpenSearch)
  end
    .tap do |method|
      # noinspection SpellCheckingInspection
      add_api method => {
        alias: {
          limit:          :count,
          query:          :q
        },
        required: {
          q:              String,
        },
        optional: {
          format:         String,   # Values: "rss" or "atom" (default).
          start:          Integer,
          count:          Integer,  # Default: 10
          servicelevel:   String,   # Values: "full" or "default" (default).
          frbrGrouping:   String,   # Values: "off" or "on" (default).
        },
        role: :anonymous,           # Should succeed for any user.
      }
    end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Aggregate terms into groups of similar search behavior.
  #
  # All query-related keys are removed from *opt*.
  #
  # @param [LookupService::Request, Array<String>, String] terms
  # @param [Hash]                                          opt
  #
  # @return [Hash{Symbol=>LookupService::WorldCat::Action::Records::Terms}]
  #
  # @see LookupService::Request#TEMPLATE
  #
  def query_terms(terms, opt)
    result = { ids: IdTerms.new, query: QueryTerms.new, limit: LimitTerms.new }
    groups = result.values

    if terms.is_a?(LookupService::Request)
      terms.request.each_pair do |type, items|
        items.each { |item| result[type].add(item) }
      end
      terms = nil
    end

    [*terms, *opt.delete(:q), *opt.delete(:query)].flatten.each do |term|
      next if groups.any? { |group| group.add(term) }
      _, item = term.split(':', 2)
      result[:query].add(:keyword, (item || term))
    end

    groups.each do |group|
      opt.extract!(*group.allowed_prefixes).each_pair do |param, value|
        group.add_terms(param, value)
      end
    end

    result.compact_blank!
  end

  # Combine terms to make a WorldCat query string.
  #
  # @param [Hash{Symbol=>Terms}] type_group
  #
  # @return [String]
  #
  def make_query(type_group)
    type_group.map { |type, group|
      inclusive = (type == :ids)
      group.parts.join(inclusive ? OR : AND)
    }.join(AND)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  OR  = ' OR '
  AND = ' AND '

  # Abstract base class for term groups.
  #
  class Terms < Hash

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Create a new query term group.
    #
    # @param [Hash{Symbol=>Symbol}] table
    #
    def initialize(table)
      @table = table
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A reference to either #LIMIT_PREFIX or #QUERY_PREFIX.
    #
    # @return [Hash{Symbol=>Symbol}]
    #
    attr_reader :table

    # Term prefixes expected for the subclass.
    #
    # @return [Array<Symbol>]
    #
    def allowed_prefixes
      table.keys
    end

    # search_codes
    #
    # @return [Array<Symbol>]
    #
    def search_codes
      table.values
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Add one or more term values of the same kind.
    #
    # @param [Symbol]   prefix
    # @param [any, nil] item
    # @param [Proc]     blk           Applied to each term value.
    #
    # @return [self, nil]
    #
    # @yield [term] Modify or replace the given term value.
    # @yieldparam [String] term       Term value
    # @yieldreturn [String]           The value to use in place of *term*.
    #
    def add_terms(prefix, item, &blk)
      values = item.is_a?(Array) ? item.flatten : Array.wrap(item)
      values.map! { |v| v.to_s.strip }.compact_blank!
      values.map!(&blk) if blk
      add(prefix, values)
    end

    # Add a single term.
    #
    # @param [Symbol, String, nil]            prefix
    # @param [Array<String,nil>, String, nil] value
    #
    # @return [self, nil]
    #
    def add(prefix, value = :missing)
      prefix, value = prefix.to_s.split(':', 2) if value == :missing
      return unless (code  = table[prefix&.to_sym])
      return unless (value = Array.wrap(value).compact_blank).present?
      self[code] += value if self[code]
      self[code]  = value unless self[code]
      self
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Form WorldCat query parts for each of the types included in the instance.
    #
    # @return [Array<String>]
    #
    def parts
      map do |code, values|
        values.uniq.map! { |v| query_part(code, v) }.join(OR)
      end
    end

    # Form a WorldCat query part to match the given value.
    #
    # @param [Symbol] code
    # @param [String] value
    #
    # @return [String]
    #
    def query_part(code, value)
      value = fix_name(value) if code == :au
      matching = value.include?(' ') ? 'exact' : '='
      %Q(srw.#{code} #{matching} "#{value}")
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Some adjustments for author queries based on observations:
    #
    # * WorldCat can handle "King, Stephen" but not "King,Stephen".
    # * "Stephen King" works for an '=' match.
    # * "King, Stephen" is required for an 'exact' match.
    # * Including birth/death dates is problematic for an 'exact' match.
    #
    # @param [String] value
    #
    # @return [String]
    #
    def fix_name(value)
      value = value.strip
      # Remove trailing date.
      value.sub!(/\s*,?\s*(\[.*\]|\(.*\)|\d+.*\d+|\d+-?)$/, '')
      # Adjust family and given names.
      case value
        when /^([^\s,]+)\s*,\s*(.*)$/ then names = [$1, $2]
        when /^(.+)\s+([^\s]+)$/      then names = [$2, $1]
        else                               names = [value, nil]
      end
      names.map! { |v| v&.gsub(/[[:punct:]]/, ' ')&.squish }.compact_blank!
      names.join(', ')
    end

  end

  # Terms which limit search results.
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  class LimitTerms < Terms

    # Method keyword parameter mapped to prefix (to be appended to "srw.") for
    # query limiters.
    #
    # Entries marked with [F] are only honored for "servicelevel=full".
    #
    # @type [Hash{Symbol=>Symbol}]
    #
    LIMIT_PREFIX = {
      dewey:      :dd,  #     "Dewey Classification Number"
      dlc:        :pc,  # [F] "DLC Limit (searches 'dlc' only)"
      doc_type:   :dt,  #     "Document Type (Primary)"
      lang_code:  :la,  #     "Language Code (Primary)"
      lang:       :ln,  # [F] "Language"
      group:      :cg,  # [F] "Library Holdings Group"
      holdings:   :li,  #     "Library Holdings"
      type:       :mt,  #     "Material Type"
      odl:        :on,  #     "Open Digital Limit"
      year:       :yr,  #     "Year"
    }.freeze

    # =========================================================================
    # :section: LookupService::WorldCat::Action::Records::Terms overrides
    # =========================================================================

    public

    # Create a new term group instance.
    #
    def initialize
      super(LIMIT_PREFIX)
    end

  end

  # Terms which specify search results.
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  class QueryTerms < Terms

    # Method keyword parameter mapped to prefix (to be appended to "srw.") for
    # query terms.
    #
    # Entries marked with [F] are only honored for "servicelevel=full".
    #
    # @type [Hash{Symbol=>Symbol}]
    #
    QUERY_PREFIX = {
      access:     :am,  # [F] "Access Method"
      author:     :au,  #     "Author"
      corporate:  :cn,  # [F] "Corporate/Conference Name"
      govdoc:     :gn,  # [F] "Government Document Number"
      isbn:       :bn,  #     "ISBN"
      issn:       :in,  #     "ISSN"
      keyword:    :kw,  #     "Keyword"
      lc:         :lc,  # [F] "LC Classification Number"
      lccn:       :dn,  #     "LCCN"
      music:      :mt,  # [F] "Music/Publisher Number"
      notes:      :nt,  # [F] "Notes"
      oclc:       :no,  #     "OCLC Number"
      name:       :pn,  # [F] "Personal name"
      place:      :pl,  # [F] "Place of publication"
      publisher:  :pb,  # [F] "Publisher"
      series:     :se,  # [F] "Series"
      number:     :sn,  # [F] "Standard Number"
      subject:    :su,  #     "Subject"
      title:      :ti,  #     "Title"
    }.freeze

    # =========================================================================
    # :section: LookupService::WorldCat::Action::Records::Terms overrides
    # =========================================================================

    public

    # Create a new term group instance.
    #
    def initialize
      super(QUERY_PREFIX)
    end

  end

  # The subset of search terms related to finding specific items by identifier.
  #
  class IdTerms < QueryTerms

    # Value prefixes specifically for publication identifiers.
    #
    # @type [Array<Symbol>]
    #
    ID_PREFIXES = %i[isbn oclc lccn issn].freeze

    # =========================================================================
    # :section: LookupService::WorldCat::Action::Records::Terms overrides
    # =========================================================================

    public

    # Term identifier prefixes.
    #
    # @return [Array<Symbol>]
    #
    def allowed_prefixes
      ID_PREFIXES
    end

    # Add one or more term values of the same kind.
    #
    # @param [Symbol]   prefix
    # @param [any, nil] item
    #
    # @return [self, nil]
    #
    def add_terms(prefix, item)
      super do |term|
        pre, val = term.split(':', 2)
        ID_PREFIXES.include?(pre.to_sym) ? val : term
      end
    end

  end

end

__loading_end(__FILE__)
