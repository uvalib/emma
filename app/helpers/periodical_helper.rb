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

  include ModelHelper
  include EditionHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  PERIODICAL_CONFIGURATION = Model.configuration('emma.periodical').deep_freeze
  PERIODICAL_INDEX_FIELDS  = PERIODICAL_CONFIGURATION.dig(:index, :fields)
  PERIODICAL_SHOW_FIELDS   = PERIODICAL_CONFIGURATION.dig(:show,  :fields)

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
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_link(item, **opt)
    opt[:path]    = periodical_path(id: item.identifier)
    opt[:tooltip] = PERIODICAL_SHOW_TOOLTIP
    item_link(item, **opt)
  end

  # Item categories as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #periodical_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  # Compare with:
  # TitleHelper#category_links
  #
  def periodical_category_links(item, **opt)
    opt[:field]     = :categories
    opt[:all_words] = true
    periodical_search_links(item, **opt)
  end

  # Item formats as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #periodical_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  # Compare with:
  # TitleHelper#format_links
  #
  def periodical_format_links(item, **opt)
    opt[:field]     = :fmt
    opt[:all_words] = true
    periodical_search_links(item, **opt)
  end

  # Item languages as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #periodical_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  # Compare with:
  # TitleHelper#language_links
  #
  def periodical_language_links(item, **opt)
    opt[:field]     = :language
    opt[:all_words] = true
    periodical_search_links(item, **opt)
  end

  # Item countries as search links.
  #
  # NOTE: This is apparently not working in Bookshare.
  # Although an invalid country code will result in no results, all valid
  # country codes result in the same results.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #periodical_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  # Compare with:
  # TitleHelper#country_links
  #
  def periodical_country_links(item, **opt)
    opt[:field]     = :country
    opt[:all_words] = true
    opt[:no_link]   = true
    periodical_search_links(item, **opt)
  end

  # Item terms as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  def periodical_search_links(item, **opt)
    opt[:link_method] = :periodical_search_link
    opt[:field]     ||= :title
    search_links(item, **opt)
  end

  # Create a link to the search results index page for the given term(s).
  #
  # @param [String] terms
  # @param [Hash]   opt                 Passed to #search_link.
  #
  # @option opt [Symbol]  :field
  # @option opt [Boolean] :all_words
  # @option opt [Boolean] :no_link
  #
  # @return [ActiveSupport::SafeBuffer] An HTML link element.
  # @return [nil]                       If no *terms* were provided.
  #
  def periodical_search_link(terms, **opt)
    opt[:scope]   = :periodical
    opt[:field] ||= :title
    search_link(terms, **opt)
  end

  # Create a link to latest periodical edition.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #edition_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def latest_edition_link(item, **opt)
    opt[:edition] = item.latestEdition&.identifier
    opt[:label] ||= opt[:edition]
    edition_link(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Bs::Api::Record] item
  # @param [Object]          value
  #
  # @return [Object]  HTML or scalar value.
  # @return [nil]     If *value* was nil or *item* resolved to nil.
  #
  # @see ModelHelper#render_value
  #
  def periodical_render_value(item, value)
    case field_category(value)
      when :title         then periodical_link(item)
      when :latestEdition then latest_edition_link(item)
      when :category      then periodical_category_links(item)
      when :language      then periodical_language_links(item)
      when :country       then periodical_country_links(item)
      else                     render_value(item, value)
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render an item metadata listing.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML element.
  # @return [nil]                         If *item* is blank.
  #
  def periodical_details(item, opt = nil)
    pairs = PERIODICAL_SHOW_FIELDS.merge(opt || {})
    item_details(item, :periodical, pairs)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_list_entry(item, opt = nil)
    pairs = PERIODICAL_INDEX_FIELDS.merge(opt || {})
    item_list_entry(item, :periodical, pairs)
  end

end

__loading_end(__FILE__)
