# app/services/lookup_service/_data.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bibliographic information extracted from one or more search result items
# returned by an external service.
#
class LookupService::Data

  # @return [Hash{Symbol=>Array<LookupService::Data::Item>}]
  attr_reader :table

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Api::Message, Faraday::Response, Hash, Array, String, LookupService::Data, LookupService::Data::Item, nil] src
  #
  # @see LookupService::RemoteService#transform
  #
  def initialize(src = nil)
    tab = dia = nil
    if src.is_a?(LookupService::Data)
      tab = src.table&.deep_dup || {}
    elsif src.is_a?(Hash) && src.key?(:items)
      dia = src[:diagnostic]
      src = src[:items]
    elsif src.is_a?(Hash) && src.key?(:diagnostic)
      src = src.dup
      dia = src.delete(:diagnostic)
    elsif !src.is_a?(LookupService::Data::Item)
      Log.warn("#{self.class}: #{src.class}: unexpected")
    end
    @table      = tab || make_table(src)
    @diagnostic = dia.presence
  end

  # Return only the fields which are not blank.
  #
  # @return [Hash{Symbol,Hash{Symbol=>Array<Hash>}}]
  #
  def item_values
    @item_values ||= table.transform_values { _1.map(&:item_values) }
  end

  # Total number of items in this instance.
  #
  # @return [Integer]
  #
  def item_count
    item_values.values.compact.sum { _1.is_a?(Array) ? _1.size : 1 }
  end

  # Out-of-band information related to this set of data.
  #
  # @return [Hash{Symbol=>Array<Hash>}]
  #
  def diagnostic
    @diagnostic ||= table.transform_values { _1.map(&:diagnostic) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # make_table
  #
  # @param [Hash, Array, nil] items
  #
  # @return [Hash{Symbol=>Array<LookupService::Data::Item>}]
  #
  def make_table(items)
    result = {}
    items  = items.values  if items.is_a?(Hash)
    items  = items.flatten if items.is_a?(Array)
    Array.wrap(items).each do |item|
      next if item.blank?
      item = LookupService::Data::Item.wrap(item)
      key  = item.identifier.to_sym
      case result[key]
        when Array then result[key] << item
        when nil   then result[key] = [item]
        else            result[key] = [result[key], item]
      end
    end
    result
  end

  # transform_table_items
  #
  # @param [Proc] blk
  #
  # @raise [ArgumentError]  If no block was given.
  #
  # @return [Hash]
  #
  # @yield [item]
  # @yieldparam [LookupService::Data::Item] item
  # @yieldreturn [any, nil]
  #
  # @note Currently unused.
  # :nocov:
  def transform_table_items(&blk)
    raise ArgumentError, 'no block given' unless blk
    table.transform_values { _1.map(&blk) }
  end
  # :nocov:

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance from *item* if it is not already an instance.
  #
  # @param [any, nil] item            LookupService::Data or arg to initializer
  #
  # @return [LookupService::Data]
  #
  def self.wrap(item)
    item.is_a?(self) ? item : new(item)
  end

end

# Bibliographic information extracted from a single search result item returned
# by an external service.
#
class LookupService::Data::Item < Search::Record::MetadataRecord

  schema_from superclass

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Although, for convenience, this class uses the full schema of its parent
  # these are the only fields which will be reported.
  #
  # @type [Array<Symbol>]
  #
  FIELDS = %i[
    dc_title
    dc_creator
    dc_identifier
    dc_subject
    dc_language
    dc_publisher
    dc_description
    bib_series
    bib_seriesType
    bib_seriesPosition
    emma_publicationDate
    dcterms_dateCopyright
  ].freeze

  TEMPLATE = FIELDS.map { [_1, nil] }.to_h.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [Hash, nil]
  attr_reader :diagnostic

  # Initialize a new instance.
  #
  # @param [Api::Message, Faraday::Response, Hash, String, LookupService::Data::Item, nil] src
  # @param [Hash, nil] opt
  #
  # @option opt [Hash] :diagnostic    Out-of-band information to include with
  #                                     the return of #item_values.
  #
  def initialize(src = nil, opt = nil)
    @diagnostic = nil
    if src.is_a?(LookupService::Data::Item)
      @diagnostic = src.diagnostic&.deep_dup
      src         = src.item_values
    elsif src.is_a?(Hash) && src.key?(:diagnostic)
      src         = src.dup
      @diagnostic = src.delete(:diagnostic)
    end
    if opt.is_a?(Hash) && opt.key?(:diagnostic)
      Log.warn("#{self.class}: opt[:diagnostic] replacing src[:diagnostic]")
      opt         = opt.dup
      @diagnostic = opt.delete(:diagnostic)
    end
    super
    normalize_dates!
  end

  # Return only the fields which are not blank.
  #
  # @return [Hash]
  #
  def item_values
    reject_blanks(fields)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # If it's just "YYYY-01-01", replace :emma_publicationDate with
  # :dcterms_dateCopyright; if not, eliminate :dcterms_dateCopyright if just
  # indicates the same year as the publication date.
  #
  # @return [void]
  #
  def normalize_dates!
    pub_date = self.emma_publicationDate&.to_s
    pub_year = pub_date&.first(4)
    if pub_date&.end_with?('-01-01')
      self.dcterms_dateCopyright ||= IsoYear.new(pub_year)
      cpr_date = self.dcterms_dateCopyright.to_s
      self.emma_publicationDate  = nil if cpr_date == pub_year
    elsif (cpr_date = self.dcterms_dateCopyright&.to_s)
      self.dcterms_dateCopyright = nil if cpr_date == pub_year
    end
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  def field_names
    FIELDS
  end

  def identifier
    Array.wrap(dc_identifier).first.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Set @diagnostic value.
  #
  # @param [Hash, nil] value
  #
  # @return [Hash]
  #
  def set_diagnostic(value)
    unless value.nil? || value.is_a?(Hash)
      Log.warn("#{self.class}: diagnostic: not Hash: #{value.inspect}")
      value = nil
    end
    @diagnostic = value || {}
  end

  alias :diagnostic= :set_diagnostic

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance from *item* if it is not already an instance.
  #
  # @param [any, nil] item            LookupService::Data::Item
  #
  # @return [LookupService::Data::Item]
  #
  def self.wrap(item)
    item.is_a?(self) ? item : new(item)
  end

end

__loading_end(__FILE__)
