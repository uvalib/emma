# app/helpers/periodical_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# PeriodicalHelper
#
module PeriodicalHelper

  def self.included(base)
    __included(base, '[PeriodicalHelper]')
  end

  include ResourceHelper
  include PaginationHelper

  # Default link tooltip.
  #
  # @type [String]
  #
  PERIODICAL_SHOW_TOOLTIP = I18n.t('emma.periodical.show.tooltip').freeze

  # Default number of results per page if none was specified.
  #
  # @type [Integer]
  #
  DEFAULT_PERIODICAL_PAGE_SIZE = DEFAULT_PAGE_SIZE

  # ===========================================================================
  # :section: PaginationHelper overrides
  # ===========================================================================

  public

  # Default tooltip for item links.
  #
  # @return [String]
  #
  # This method overrides:
  # @see PaginationHelper#default_show_tooltip
  #
  def default_show_tooltip
    PERIODICAL_SHOW_TOOLTIP
  end

  # Default of results per page.
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see PaginationHelper#default_page_size
  #
  def default_page_size
    DEFAULT_PERIODICAL_PAGE_SIZE
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of periodical results.
  #
  # @return [Array<PeriodicalSeriesMetadataSummary>]
  #
  def periodical_list
    page_items
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Object]              item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash, nil]           opt    @see ResourceHelper#item_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_link(item, label = nil, **opt)
    path = periodical_path(id: item.identifier)
    item_link(item, label, path, **opt)
  end

  # Item categories as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #periodical_search_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_category_links(item, **opt)
    opt = opt.merge(all_words: true)
    periodical_search_links(item, :categories, **opt)
  end

  # Item formats as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #periodical_search_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_format_links(item, **opt)
    opt = opt.merge(method: :format, all_words: true)
    periodical_search_links(item, :format, **opt)
  end

  # Item languages as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #periodical_search_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_language_links(item, **opt)
    opt = opt.merge(all_words: true)
    periodical_search_links(item, :language, **opt)
  end

  # Item countries as search links.
  #
  # NOTE: This is apparently not working in Bookshare.
  # Although an invalid country code will result in no results, all valid
  # country codes result in the same results.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #periodical_search_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_country_links(item, **opt)
    opt = opt.merge(all_words: true, no_link: true)
    periodical_search_links(item, :country, **opt)
  end

  # Item terms as search links.
  #
  # @param [Object]      item
  # @param [Symbol, nil] field        Default: :keyword
  # @param [Hash, nil]   opt
  #
  # @option opt [Symbol, String] :field
  # @option opt [Symbol]         :method
  # @option opt [String]         :separator   Def.: #DEFAULT_ELEMENT_SEPARATOR
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def periodical_search_links(item, field = nil, **opt)

    field  = opt[:field]  || field || :title
    method = opt[:method] || field.to_s.pluralize.to_sym
    return unless item.respond_to?(method)

    sep  = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    opt  = opt.except(:field, :method, :separator)
    null = opt.include?(:no_link).presence
    Array.wrap(item.send(method)).map { |s|
      no_link = null
      no_link ||=
        case field
          when :categories then !s.bookshare_category
        end
      link_opt = no_link ? opt.merge(no_link: no_link) : opt
      periodical_search_link(s, field, **link_opt)
    }.sort.uniq.join(sep).html_safe

  end

  # Create a link to the search results index page for the given term(s).
  #
  # @param [String]                     terms
  # @param [Symbol, Array<Symbol>, nil] field   Default: :keyword
  # @param [Hash, nil]                  opt
  #
  # @option opt [Symbol]  :field
  # @option opt [Boolean] :all_words
  # @option opt [Boolean] :no_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_search_link(terms, field = nil, **opt)
    label   = terms = terms.to_s
    field   = opt[:field] || field || :title
    words   = opt[:all_words]
    no_link = opt[:no_link]
    opt     = opt.except(:field, :all_words, :no_link)

    # If this instance should not be rendered as a link, return now.
    return content_tag(:span, label, **opt) if no_link

    # Otherwise, wrap the terms phrase in quotes unless directed to handled
    # each word of the phrase separately.
    if words
      words = terms.split(/\s/).compact.map { |t| %Q("#{t}") }
      tip_terms = +''
      tip_terms << 'containing ' if words.size > 1
      tip_terms << words.join(', ')
    else
      tip_terms = terms = %Q("#{terms}")
    end
    opt[:title] =
      I18n.t('emma.periodical.index.tooltip', terms: "#{field} #{tip_terms}")
    search = Array.wrap(field).map { |f| [f, terms] }.to_h
    path   = periodical_index_path(search)
    link_to(label, path, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fields from  Api::PeriodicalSeriesMetadataSummary.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # Compare with:
  # @see TitleHelper#TITLE_SHOW_FIELDS
  #
  PERIODICAL_SHOW_FIELDS = {

    # === Description ===
    Year:                 :year,
    Languages:            :languages,
    Description:          :description,
    Categories:           :categories,
    Countries:            :countries,

    # === Identifiers ===
    ISSN:                 :issn,
    ExternalCategoryCode: :externalCategoryCode,

    # === Publisher/provider information ===
    Publisher:            :publisher,

    # === Item instances ===
    LatestEdition:        :latestEdition,
    Editions:             :editionCount,

    # === Bookshare information ===
    SeriesId:             :seriesId,
    Links:                :links,

  }.freeze

  # periodical_field_values
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         opt
  #
  # @return [Hash{Symbol=>Object}]
  #
  def periodical_field_values(item, **opt)
    field_values(item) do
      eid = item.latestEdition.identifier
      PERIODICAL_SHOW_FIELDS.merge(opt).transform_values do |v|
        case v
          when :latestEdition then edition_link(item, eid, edition: eid)
          when :categories    then periodical_category_links(item)
          when :formats       then periodical_format_links(item)
          when :languages     then periodical_language_links(item)
          when :countries     then periodical_country_links(item)
          else                     v
        end
      end
    end
  end

end

__loading_end(__FILE__)
