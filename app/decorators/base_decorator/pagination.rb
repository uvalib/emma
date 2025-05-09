# app/decorators/base_decorator/pagination.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods pagination of Model instance lists.
#
module BaseDecorator::Pagination

  include BaseDecorator::Common
  include BaseDecorator::Configuration
  include BaseDecorator::Links

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for pagination control properties.
  #
  # @type [Hash]
  #
  PAGINATION_CONFIG = config_page_section(:pagination).deep_freeze

  # Separator between pagination controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PAGINATION_SEPARATOR = PAGINATION_CONFIG[:separator].html_safe.freeze

  # Nominal default page size.
  #
  # @type [Integer]
  #
  DEFAULT_PAGE_SIZE = PAGINATION_CONFIG[:page_size]

  # Properties for the "start over" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  # === Usage Notes
  # To link to the base search without any search terms (a.k.a. "null search").
  #
  START_OVER = PAGINATION_CONFIG[:start_over]

  # Properties for the "first page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  FIRST_PAGE = PAGINATION_CONFIG[:first_page]

  # Properties for the "last page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  LAST_PAGE = PAGINATION_CONFIG[:last_page]

  # Properties for the "previous page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  PREV_PAGE = PAGINATION_CONFIG[:prev_page]

  # Properties for the "next page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  NEXT_PAGE = PAGINATION_CONFIG[:next_page]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generic top/bottom pagination controls.
  #
  # @param [Array<ActiveSupport::SafeBuffer>] ctrls
  # @param [Integer, nil] row
  # @param [Hash]         opt         Passed to #page_count_and_number
  #
  # @return [Array(ActiveSupport::SafeBuffer,ActiveSupport::SafeBuffer)]
  #
  def page_content_controls(*ctrls, row: nil, **opt)
    links   = pagination_controls
    counts  = page_count_and_number(**opt)
    top     = pagination_top(*ctrls, counts, links, row: row)
    bottom  = pagination_bottom(links)
    return top, bottom
  end

  # Used to supply pagination- and content-specific controls for display above
  # the content.
  #
  # @param [Array<ActiveSupport::SafeBuffer>] parts
  # @param [Integer, nil]                     row
  # @param [String]                           css   Characteristic CSS class.
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_top(*parts, row: nil, css: '.pagination-top', **opt)
    prepend_css!(opt, "row-#{row}") if row
    prepend_css!(opt, css)
    html_div(*parts, **opt)
  end

  # Used to supply pagination- and content-specific controls for display below
  # the content.
  #
  # @param [Array<ActiveSupport::SafeBuffer>] parts
  # @param [Integer, nil]                     row
  # @param [String]                           css   Characteristic CSS class.
  # @param [Hash]                             opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_bottom(*parts, row: nil, css: '.pagination-bottom', **opt)
    prepend_css!(opt, "row-#{row}") if row
    prepend_css!(opt, css)
    html_div(*parts, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Page count along with the page number when appropriate.
  #
  # @param [Array,   nil] list        Page items.
  # @param [Integer, nil] count       Default: *list* size.
  # @param [Integer, nil] total       Default: `paginator.total_items`.
  # @param [Integer, nil] records     Default: `paginator.record_count`.
  # @param [Integer, nil] page        Default: `paginator.page_number`.
  # @param [Integer, nil] size        Default: `paginator.page_size`.
  # @param [String,  nil] unit        Name for one page item.
  # @param [String]       css         Characteristic CSS class/selector.
  # @param [Hash]         opt         Passed to the outer div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def page_count_and_number(
    list:    nil,
    count:   nil,
    total:   nil,
    records: nil,
    page:    nil,
    size:    nil,
    unit:    nil,
    css:    '.counts',
    **opt
  )
    count   = positive(count)   || list&.size
    total   = positive(total)   || paginator.total_items
    records = positive(records) || paginator.record_count
    size    = positive(size)    || paginator.page_size
    page    = positive(page)    || paginator.page_number || 1
    count ||= size || list&.size.to_i
    size  ||= DEFAULT_PAGE_SIZE
    more    = (page > 1) || total.nil?
    more  ||= (count < total) && (total == size)
    more  ||= (count == size) || (records == size)
    total   = nil if total == size

    parts   = []
    parts  << page_number(page) if more
    parts  << pagination_count(count, total, unit: unit)

    prepend_css!(opt, css)
    html_div(*parts, **opt)
  end

  # Page number display element.
  #
  # @param [Integer] page
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Options to .page-count wrapper element.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *count* is negative.
  #
  def page_number(page, css: '.page-count', **opt)
    page  = positive(page) or return
    pages = get_page_number_label(count: page)&.upcase_first
    prepend_css!(opt, css)
    html_div("#{pages} #{page}", **opt)
  end

  # Page count display element.
  #
  # The text of elements with these selectors are notable:
  #
  # * ".page-items"   The number of items displayed on the page.
  # * ".total-items"  The total number of items across all pages.
  #
  # @param [Integer, nil] count
  # @param [Integer, nil] total
  # @param [String,  nil] unit        Name for one page item.
  # @param [String]       css         Characteristic CSS class/selector.
  # @param [Hash]         opt         Options to .search-count wrapper.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_count(
    count,
    total = nil,
    unit:   nil,
    css:    '.search-count',
    **opt
  )
    count = positive(count).to_i
    total = positive(total)&.to_i || count
    found = get_page_count_label(count: total, item: unit)
    found = found.pluralize(count)
    txt   = ->(t, *c) { html_span(t, class: css_classes(*c)) }
    num   = ->(n, *c) { txt.(h.number_with_delimiter(n), *c) }
    label = [
      txt.('(',         'left-side',    'single-page'),
      num.(count,       'page-items',   'multi-page'),
      txt.(' of ',      'text',         'multi-page'),
      num.(total,       'total-items',  'multi-page', 'single-page'),
      txt.(" #{found}", 'text',         'multi-page', 'single-page'),
      txt.(')',         'right-side',   'single-page'),
    ]
    prepend_css!(opt, css, ((total > count) ? 'multi-page' : 'single-page'))
    html_div(separator: '', **opt) { label }
  end

  # Placeholder for an item that would have been a link if it had a path.
  #
  # @param [String, Hash, nil] fp     Passed to #pagination_first.
  # @param [String, Hash, nil] pp     Passed to #pagination_prev.
  # @param [String, Hash, nil] np     Passed to #pagination_next.
  # @param [String, nil]       sep    Passed to #pagination_separator.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt    For .pagination-controls container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Implementation Notes
  # Capybara test seem to have a consistent problem when Turbolinks is allowed
  # to manage the "next page" link, so it is explicitly avoided during tests.
  #
  def pagination_controls(
    fp:  nil,
    pp:  nil,
    np:  nil,
    sep: nil,
    css: '.pagination-controls',
    **opt
  )
    fp_opt = pp_opt = np_opt = { class: 'link' }
    np_opt = np_opt.merge('data-turbolinks': false) if Rails.env.test?
    fp = pagination_first(fp, **fp_opt)
    pp = pagination_prev( pp, **pp_opt)
    np = pagination_next( np, **np_opt)
    prepend_css!(opt, css)
    html_tag(:nav, fp, pp, np, **opt, separator: pagination_separator(sep))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Page number label for the model type.
  #
  # @param [Hash] opt               Passed to #config_lookup
  #
  # @return [String]                The specified value.
  # @return [nil]                   No non-empty value was found.
  #
  def get_page_number_label(**opt)
    config_lookup('pagination.page', **opt)
  end

  # Page count label for the model type.
  #
  # @param [Hash] opt               Passed to #config_lookup
  #
  # @option opt [Integer] :count
  # @option opt [String]  :unit
  #
  # @return [String]                The specified value.
  # @return [nil]                   No non-empty value was found.
  #
  def get_page_count_label(**opt)
    config_lookup('pagination.count', **opt)
  end

  # The element used to visually separate pagination control icons.
  #
  # @param [String, nil] content      Default: `#PAGINATION_SEPARATOR`.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_separator(content = nil, css: '.separator', **opt)
    prepend_css!(opt, css)
    html_span(**opt) do
      content || PAGINATION_SEPARATOR
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The object used to support movement within a set of results.
  #
  # @return [Paginator]
  #
  def paginator
    @paginator ||= context[:paginator] || Paginator.new(h.controller)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A control for moving to the first page of a set of results.
  #
  # @param [String, Hash, nil] path   Default: `#paginator.first_page`.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_first(path = nil, css: '.first', **opt)
    path         ||= paginator.first_page
    opt[:prefix] ||= pagination_first_icon
    append_css!(opt, css)
    pagination_control(FIRST_PAGE, path, **opt)
  end

  # A control for moving to the previous page of a set of results.
  #
  # @param [String, Hash, nil] path   Default: `#paginator.prev_page`.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_prev(path = nil, css: '.prev', **opt)
    path         ||= paginator.prev_page
    opt[:prefix] ||= pagination_prev_icon
    opt[:rel]    ||= 'prev'
    append_css!(opt, css)
    pagination_control(PREV_PAGE, path, **opt)
  end

  # A control for moving to the next page of a set of results.
  #
  # @param [String, Hash, nil] path   Default: `#paginator.next_page`.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_next(path = nil, css: '.next', **opt)
    path         ||= paginator.next_page
    opt[:suffix] ||= pagination_next_icon
    opt[:rel]    ||= 'next'
    append_css!(opt, css)
    pagination_control(NEXT_PAGE, path, **opt)
  end

  # A control for moving to the last page of a set of results.
  #
  # @param [String, Hash, nil] path   Default: `#paginator.last_page`.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @note Currently unused.
  # :nocov:
  def pagination_last(path = nil, css: '.last', **opt)
    path         ||= paginator.last_page
    opt[:suffix] ||= pagination_last_icon
    append_css!(opt, css)
    pagination_control(LAST_PAGE, path, **opt)
  end
  # :nocov:

  # A pagination control link or a non-actionable placeholder if *path* is not
  # valid.
  #
  # @param [String, Hash]      label
  # @param [String, Hash, nil] path
  # @param [Hash]              opt    Passed to #make_link or "span" except:
  #
  # @option [String] :prefix
  # @option [String] :suffix
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_control(label, path, **opt)
    link = path.present?
    if label.is_a?(Hash)
      prop  = label
      label = prop[:label] || '(missing)'
      tip   = link ? prop[:tooltip] : prop.dig(:no_link, :tooltip)
      opt[:title] = tip if tip.present?
    end
    label  = html_span(label, class: 'label')
    prefix = opt.delete(:prefix)
    suffix = opt.delete(:suffix)
    label  = safe_join([prefix, label, suffix].compact)
    if link
      make_link(path, label, **opt)
    else
      html_span(label, **append_css!(opt, 'disabled'))
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The icon for a control for moving to the first page of a set of results.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_first_icon(css: '.square-icon', **opt)
    pagination_icon(**opt, css: css)
  end

  # The icon for a control for moving to the previous page of a set of results.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/stylesheets/layouts/controls/_shapes.scss
  #
  def pagination_prev_icon(css: '.left-triangle-icon', **opt)
    pagination_icon(**opt, css: css)
  end

  # The icon for a control for moving to the next page of a set of results.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/stylesheets/layouts/controls/_shapes.scss
  #
  def pagination_next_icon(css: '.right-triangle-icon', **opt)
    pagination_icon(**opt, css: css)
  end

  # The icon for a control for moving to the last page of a set of results.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/stylesheets/layouts/controls/_shapes.scss
  #
  # @note Currently used only by #pagination_last.
  # :nocov:
  def pagination_last_icon(css: '.square-icon', **opt)
    pagination_icon(**opt, css: css)
  end
  # :nocov:

  # A decorative visual representation of a control action.
  #
  # @param [String, nil] content
  # @param [Hash]        opt
  #
  # @option opt [String] :css         Appended to CSS classes.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_icon(content = nil, **opt)
    css       = '.icon'
    content ||= ''
    opt[:'aria-hidden'] = true unless opt.key?(:'aria-hidden')
    prepend_css!(opt, css, opt.delete(:css))
    html_span(content, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The element displayed when there are no items to list.
  #
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def no_items(css: '.no-items', **opt)
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
