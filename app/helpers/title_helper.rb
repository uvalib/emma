# app/helpers/title_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# TitleHelper
#
module TitleHelper

  def self.included(base)
    __included(base, '[TitleHelper]')
  end

  include ImageHelper
  include ModelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  TITLE_CONFIGURATION = model_configuration('emma.title').deep_freeze
  TITLE_INDEX_FIELDS  = TITLE_CONFIGURATION.dig(:index, :fields)
  TITLE_SHOW_FIELDS   = TITLE_CONFIGURATION.dig(:show,  :fields)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of title results.
  #
  # @return [Array<Bs::Record::TitleMetadataSummary>]
  #
  def title_list
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
  TITLE_SHOW_TOOLTIP = I18n.t('emma.title.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_link(item, **opt)
    opt[:path]    = title_path(id: item.identifier)
    opt[:tooltip] = TITLE_SHOW_TOOLTIP
    item_link(item, **opt)
  end

  # Thumbnail element for the given catalog title.
  #
  # @param [Bs::Api::Record] item
  # @param [Boolean]         link         If *true* make the image a link to
  #                                         the show page for the item.
  # @param [Hash]            opt          Passed to #image_element.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no thumbnail.
  #
  def thumbnail(item, link: false, **opt)
    url = item.respond_to?(:thumbnail_image) && item.thumbnail_image or return
    opt, html_opt = partition_options(opt, :alt, *ITEM_ENTRY_OPT)
    id   = item.identifier
    link = title_path(id: id) if link
    alt  = opt[:alt] || i18n_lookup(nil, 'thumbnail.image.alt', item: id)
    row  = positive(opt[:row])
    prepend_css_classes!(html_opt, 'thumbnail')
    html_opt[:id] = "container-img-#{id}"
    html_opt[:'data-turbolinks-permanent'] = true
    # noinspection RubyYardParamTypeMatch
    image_element(url, link: link, alt: alt, row: row, **html_opt)
  end

  # Cover image element for the given catalog title.
  #
  # @param [Bs::Api::Record] item
  # @param [Boolean]         link         If *true* make the image a link to
  #                                         the show page for the item.
  # @param [Hash]            opt          Passed to #image_element.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no cover image.
  #
  def cover_image(item, link: false, **opt)
    url = item.respond_to?(:cover_image) && item.cover_image or return
    opt, html_opt = partition_options(opt, :alt, *ITEM_ENTRY_OPT)
    id   = item.identifier
    link = title_path(id: id) if link
    alt  = opt[:alt] || i18n_lookup(nil, 'cover.image.alt', item: id)
    prepend_css_classes!(html_opt, 'cover-image')
    # noinspection RubyYardParamTypeMatch
    image_element(url, link: link, alt: alt, **opt)
  end

  # Item categories as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  # Compare with:
  # PeriodicalHelper#periodical_category_links
  #
  def category_links(item, **opt)
    opt[:field] = :categories
    title_search_links(item, **opt)
  end

  # Item author(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  def author_links(item, **opt)
    opt[:field] = :author_list
    title_search_links(item, **opt)
  end

  # Item editor(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  def editor_links(item, **opt)
    opt[:field]      = :editor_list
    opt[:method_opt] = { role: true }
    title_search_links(item, **opt)
  end

  # Item composer(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  def composer_links(item, **opt)
    opt[:field]      = :composer_list
    opt[:method_opt] = { role: true }
    title_search_links(item, **opt)
  end

  # Item narrator(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  def narrator_links(item, **opt)
    opt[:field]      = :narrator_list
    opt[:method_opt] = { role: true }
    title_search_links(item, **opt)
  end

  # Item creator(s) as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  def creator_links(item, **opt)
    opt[:field]      = :creator_list
    opt[:method_opt] = { role: true }
    title_search_links(item, **opt)
  end

  # Item formats as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  # Compare with:
  # PeriodicalHelper#periodical_format_links
  #
  def format_links(item, **opt)
    opt[:field]     = :fmt
    opt[:all_words] = true
    title_search_links(item, **opt)
  end

  # Item languages as search links.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  # Compare with:
  # PeriodicalHelper#periodical_language_links
  #
  def language_links(item, **opt)
    opt[:field]     = :language
    opt[:all_words] = true
    title_search_links(item, **opt)
  end

  # Item countries as search links.
  #
  # NOTE: This is apparently not working in Bookshare.
  # Although an invalid country code will result in no results, all valid
  # country codes result in the same results.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  # Compare with:
  # PeriodicalHelper#periodical_country_links
  #
  def country_links(item, **opt)
    opt[:field]     = :country
    opt[:all_words] = true
    opt[:no_link]   = true
    title_search_links(item, **opt)
  end

  # Catalog item search links.
  #
  # Items in returned in two separately sorted groups: actionable links (<a>
  # elements) followed by items which are not linkable (<span> elements).
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt        Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If access method unsupported by *item*.
  #
  def title_search_links(item, **opt)
    opt[:link_method] = :title_search_link
    opt[:field]     ||= :keyword
    search_links(item, **opt)
  end

  # A link to the catalog item search results index page for the given term(s).
  #
  # @param [String] terms
  # @param [Hash]   opt                 Passed to #search_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If no *terms* were provided.
  #
  def title_search_link(terms, **opt)
    opt[:scope]   = :title
    opt[:field] ||= :keyword
    search_link(terms, **opt)
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
  # @return [Object]
  #
  # @see ModelHelper#render_value
  #
  def title_render_value(item, value)
    case field_category(value)
      when :title then title_link(item)
      else             render_value(item, value)
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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* is blank.
  #
  def title_details(item, opt = nil)
    pairs = TITLE_SHOW_FIELDS.merge(opt || {})
    item_details(item, :title, pairs)
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
  def title_list_entry(item, opt = nil)
    pairs = TITLE_INDEX_FIELDS.merge(opt || {})
    item_list_entry(item, :title, pairs)
  end

end

__loading_end(__FILE__)
