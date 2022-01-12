# app/helpers/title_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/title" pages.
#
module TitleHelper

  include BookshareHelper
  include ImageHelper

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
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_link(item, **opt)
    opt[:path]    = title_path(id: item.identifier)
    opt[:tooltip] = TITLE_SHOW_TOOLTIP
    model_link(item, **opt)
  end

  # Thumbnail element for the given catalog title.
  #
  # @param [Model, nil]      item
  # @param [Boolean, String] link         If *true* make the image a link to
  #                                         the show page for the item.
  # @param [Hash]            opt          Passed to #image_element.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML image or placeholder element.
  # @return [nil]                         If *item* is *nil*.
  #
  # == Usage Notes
  # If *item* does not contain a thumbnail, the method returns a "blank" HTML
  # element.
  #
  def thumbnail(item, link: false, **opt)
    return unless item
    css_selector  = '.thumbnail'
    opt, html_opt = partition_hash(opt, :alt, *ITEM_ENTRY_OPT)
    prepend_classes!(html_opt, css_selector)
    # noinspection RailsParamDefResolve
    if (url = item.try(:thumbnail_image)).present?
      # noinspection RubyNilAnalysis
      id   = item.identifier
      link = title_path(id: id) if link.is_a?(TrueClass)
      link = nil                if link.is_a?(FalseClass)
      alt  = opt[:alt] || config_lookup('thumbnail.image.alt', item: id)
      row  = positive(opt[:row])
      html_opt[:id] = "container-img-#{id}"
      html_opt[:'data-group'] = opt[:group] if opt[:group].present?
      html_opt[:'data-turbolinks-permanent'] = true
      # noinspection RubyMismatchedArgumentType
      image_element(url, link: link, alt: alt, row: row, **html_opt)
    else
      placeholder_element(comment: 'no thumbnail', **html_opt)
    end
  end

  # Cover image element for the given catalog title.
  #
  # @param [Bs::Api::Record, Model] item
  # @param [Boolean, String]        link  If *true* make the image a link to
  #                                         the show page for the item.
  # @param [Hash]                   opt   Passed to #image_element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # If *item* does not contain a cover image, the method returns a "blank" HTML
  # element.
  #
  def cover_image(item, link: false, **opt)
    css_selector  = '.cover-image'
    opt, html_opt = partition_hash(opt, :alt, *ITEM_ENTRY_OPT)
    prepend_classes!(html_opt, css_selector)
    html_opt[:'data-group'] = opt[:group] if opt[:group].present?
    # noinspection RailsParamDefResolve
    if (url = item.try(:cover_image)).present?
      id   = item.identifier
      link = title_path(id: id) if link.is_a?(TrueClass)
      link = nil                if link.is_a?(FalseClass)
      alt  = opt[:alt] || config_lookup('cover.image.alt', item: id)
      # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
      image_element(url, link: link, alt: alt, **html_opt)
    else
      placeholder_element(comment: 'no cover image', **html_opt)
    end
  end

  # Item categories as search links.
  #
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
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
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  def author_links(item, **opt)
    opt[:field] = :author_list
    title_search_links(item, **opt)
  end

  # Item editor(s) as search links.
  #
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  def editor_links(item, **opt)
    opt[:field]      = :editor_list
    opt[:method_opt] = { role: true }
    title_search_links(item, **opt)
  end

  # Item composer(s) as search links.
  #
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  def composer_links(item, **opt)
    opt[:field]      = :composer_list
    opt[:method_opt] = { role: true }
    title_search_links(item, **opt)
  end

  # Item narrator(s) as search links.
  #
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  def narrator_links(item, **opt)
    opt[:field]      = :narrator_list
    opt[:method_opt] = { role: true }
    title_search_links(item, **opt)
  end

  # Item creator(s) as search links.
  #
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
  # @return [nil]                       If access method unsupported by *item*.
  #
  def creator_links(item, **opt)
    opt[:field]      = :creator_list
    opt[:method_opt] = { role: true }
    title_search_links(item, **opt)
  end

  # Item formats as search links.
  #
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
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
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
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
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #title_search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
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
  # @param [Bs::Api::Record, Model] item
  # @param [Hash]                   opt   Passed to #search_links.
  #
  # @return [ActiveSupport::SafeBuffer] HTML link element(s).
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
  # @return [ActiveSupport::SafeBuffer] An HTML link element.
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
  # @param [Any]             value
  # @param [Hash]            opt      Passed to the render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  # @see BookshareHelper#bookshare_render_value
  #
  def title_render_value(item, value, **opt)
    case field_category(value)
      when :title then title_link(item)
      else             bookshare_render_value(item, value, **opt)
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing for a title.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_details.
  #
  def title_details(item, pairs: nil, **opt)
    opt[:model] = model = :title
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
  def title_list_item(item, pairs: nil, **opt)
    opt[:model] = model = :title
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
