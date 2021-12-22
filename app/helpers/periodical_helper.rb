# app/helpers/periodical_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/periodical" pages.
#
module PeriodicalHelper

  include BookshareHelper
  include EditionHelper

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
  # @param [Hash]            opt      Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def periodical_link(item, **opt)
    opt[:path]    = periodical_path(id: item.identifier)
    opt[:tooltip] = PERIODICAL_SHOW_TOOLTIP
    model_link(item, **opt)
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
  # @param [Any]             value
  # @param [Hash]            opt      Passed to the render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  # @see BookshareHelper#bookshare_render_value
  #
  def periodical_render_value(item, value, **opt)
    case field_category(value)
      when :title         then periodical_link(item, **opt)
      when :latestEdition then latest_edition_link(item, **opt)
      when :category      then periodical_category_links(item, **opt)
      when :language      then periodical_language_links(item, **opt)
      when :country       then periodical_country_links(item, **opt)
      else                     bookshare_render_value(item, value, **opt)
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing of a periodical.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_details.
  #
  def periodical_details(item, pairs: nil, **opt)
    opt[:model] = model = :periodical
    opt[:pairs] = Model.show_fields(model).merge(pairs || {})
    model_details(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_list_item.
  #
  def periodical_list_item(item, pairs: nil, **opt)
    opt[:model] = model = :periodical
    opt[:pairs] = Model.index_fields(model).merge(pairs || {})
    model_list_item(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
