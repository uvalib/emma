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

  # Default link tooltip.
  #
  # @type [String]
  #
  PERIODICAL_SHOW_TOOLTIP = I18n.t('emma.periodical.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Object]              item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash, nil]           opt    Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_link(item, label = nil, **opt)
    path = periodical_path(id: item.identifier)
    opt  = opt.merge(tooltip: PERIODICAL_SHOW_TOOLTIP)
    item_link(item, label, path, **opt)
  end

  # Item categories as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #periodical_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # Compare with:
  # TitleHelper#category_links
  #
  def periodical_category_links(item, **opt)
    opt = opt.merge(all_words: true)
    periodical_search_links(item, :categories, **opt)
  end

  # Item formats as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #periodical_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # Compare with:
  # TitleHelper#format_links
  #
  def periodical_format_links(item, **opt)
    opt = opt.merge(all_words: true)
    periodical_search_links(item, :fmt, **opt)
  end

  # Item languages as search links.
  #
  # @param [Object]    item
  # @param [Hash, nil] opt            @see #periodical_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # Compare with:
  # TitleHelper#language_links
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
  # @param [Hash, nil] opt            @see #periodical_search_links
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # Compare with:
  # TitleHelper#country_links
  #
  def periodical_country_links(item, **opt)
    opt = opt.merge(all_words: true, no_link: true)
    periodical_search_links(item, :country, **opt)
  end

  # Item terms as search links.
  #
  # @param [Object]      item
  # @param [Symbol, nil] field        Default: :title
  # @param [Hash, nil]   opt          Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def periodical_search_links(item, field = nil, **opt)
    field ||= opt[:field] || :title
    search_links(item, field, opt.merge(link_method: :periodical_search_link))
  end

  # Create a link to the search results index page for the given term(s).
  #
  # @param [String]      terms
  # @param [Symbol, nil] field        Default: :title
  # @param [Hash, nil]   opt          Passed to #search_link.
  #
  # @option opt [Symbol]  :field
  # @option opt [Boolean] :all_words
  # @option opt [Boolean] :no_link
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def periodical_search_link(terms, field = nil, **opt)
    field ||= opt[:field] || :title
    search_link(terms, field, opt.merge(scope: :periodical))
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
          when :languages     then periodical_language_links(item)
          when :countries     then periodical_country_links(item)
          else                     v
        end
      end
    end
  end

end

__loading_end(__FILE__)
