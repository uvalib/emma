# app/decorators/base_decorator/pagination.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods pagination of Model instance lists.
#
module BaseDecorator::Pagination

  include BaseDecorator::Links

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for pagination control properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection, RubyMismatchedConstantType
  #++
  PAGINATION_CONFIG = I18n.t('emma.pagination', default: {}).deep_freeze

  # Separator between pagination controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PAGINATION_SEPARATOR = PAGINATION_CONFIG[:separator].html_safe.freeze

  # Nominal default page size.
  #
  # @type [Integer]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  DEFAULT_PAGE_SIZE = PAGINATION_CONFIG[:page_size]

  # Properties for the "start over" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  # == Usage Notes
  # To link to the base search without any search terms (a.k.a. "null search").
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  START_OVER = PAGINATION_CONFIG[:start_over]

  # Properties for the "first page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  FIRST_PAGE = PAGINATION_CONFIG[:first_page]

  # Properties for the "last page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  LAST_PAGE = PAGINATION_CONFIG[:last_page]

  # Properties for the "previous page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  PREV_PAGE = PAGINATION_CONFIG[:prev_page]

  # Properties for the "next page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  NEXT_PAGE = PAGINATION_CONFIG[:next_page]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    html_div("#{pages} #{page}", opt)
  end

  # Page count display element.
  #
  # @param [Integer, nil] count
  # @param [Integer, nil] total
  # @param [String]       unit
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
    total = positive(total).to_i
    # noinspection RubyMismatchedArgumentType
    total = nil unless total > count
    prepend_css!(opt, css)
    html_div(opt) do
      found = get_page_count_label(count: (total || count), item: unit)
      words = total ? [count, 'of', total, found] : [count, found]
      label = words.map! { |v| h.number_with_delimiter(v) }.join(' ')
      total ? label : "(#{label})"
    end
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
  def pagination_controls(
    fp:  nil,
    pp:  nil,
    np:  nil,
    sep: nil,
    css: '.pagination-controls',
    **opt
  )
    prepend_css!(opt, css)
    html_tag(:nav, opt) do
      link_opt = { class: 'link', 'data-turbolinks-track': false }
      controls = [
        pagination_first(fp, **link_opt),
        pagination_prev(pp, **link_opt),
        pagination_next(np, **link_opt)
      ]
      safe_join(controls, pagination_separator(sep))
    end
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
  #
  # @return [String]                The specified value.
  # @return [nil]                   No non-empty value was found.
  #
  def get_page_count_label(**opt)
    config_lookup('pagination.count', **opt)
  end

  # pagination_separator
  #
  # @param [String, nil] content      Default: `#PAGINATION_SEPARATOR`.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_separator(content = nil, css: '.separator', **opt)
    prepend_css!(opt, css)
    html_span(opt) do
      content || PAGINATION_SEPARATOR
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # paginator
  #
  # @return [Paginator]
  #
  def paginator
    @paginator ||= context[:paginator] || Paginator.new(h.controller)
  end

  # pagination_first
  #
  # @param [String, Hash, nil] path   Default: `#paginator.first_page`.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #pagination_control
  #
  def pagination_first(path = nil, css: '.first', **opt)
    path         ||= paginator.first_page
    opt[:prefix] ||= pagination_first_icon
    append_css!(opt, css)
    pagination_control(FIRST_PAGE, path, **opt)
  end

  # pagination_prev
  #
  # @param [String, Hash, nil] path   Default: `#paginator.prev_page`.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #pagination_control
  #
  def pagination_prev(path = nil, css: '.prev', **opt)
    path         ||= paginator.prev_page
    opt[:prefix] ||= pagination_prev_icon
    opt[:rel]    ||= 'prev'
    append_css!(opt, css)
    pagination_control(PREV_PAGE, path, **opt)
  end

  # pagination_next
  #
  # @param [String, Hash, nil] path   Default: `#paginator.next_page`.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #pagination_control
  #
  def pagination_next(path = nil, css: '.next', **opt)
    path         ||= paginator.next_page
    opt[:suffix] ||= pagination_next_icon
    opt[:rel]    ||= 'next'
    append_css!(opt, css)
    pagination_control(NEXT_PAGE, path, **opt)
  end

  # pagination_last
  #
  # @param [String, Hash, nil] path   Default: `#paginator.last_page`.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #pagination_control
  #
  # @note Currently unused.
  #
  def pagination_last(path = nil, css: '.last', **opt)
    path         ||= paginator.last_page
    opt[:suffix] ||= pagination_last_icon
    append_css!(opt, css)
    pagination_control(LAST_PAGE, path, **opt)
  end

  # A pagination control link or a non-actionable placeholder if *path* is not
  # valid.
  #
  # @param [String, Hash]      label
  # @param [String, Hash, nil] path
  # @param [Hash]              opt    Passed to #link_to or "span" except for:
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
      link_to(label, path, opt)
    else
      html_span(label, append_css!(opt, 'disabled'))
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # pagination_first_icon
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #pagination_icon
  #
  def pagination_first_icon(css: '.square-icon', **opt)
    pagination_icon(**opt, css: css)
  end

  # pagination_prev_icon
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #pagination_icon
  # @see file:app/assets/stylesheets/layouts/controls/_shapes.scss
  #
  def pagination_prev_icon(css: '.left-triangle-icon', **opt)
    pagination_icon(**opt, css: css)
  end

  # pagination_next_icon
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #pagination_icon
  # @see file:app/assets/stylesheets/layouts/controls/_shapes.scss
  #
  def pagination_next_icon(css: '.right-triangle-icon', **opt)
    pagination_icon(**opt, css: css)
  end

  # pagination_last_icon
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #pagination_icon
  # @see file:app/assets/stylesheets/layouts/controls/_shapes.scss
  #
  def pagination_last_icon(css: '.square-icon', **opt)
    pagination_icon(**opt, css: css)
  end

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
    html_span(content, opt)
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
