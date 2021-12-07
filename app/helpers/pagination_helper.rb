# app/helpers/pagination_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting pagination.
#
module PaginationHelper

  include HtmlHelper
  include ParamsHelper
  include ConfigurationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for pagination control properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  PAGINATION_CONFIG = I18n.t('emma.pagination', default: {}).deep_freeze

  # Separator between pagination controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PAGINATION_SEPARATOR = PAGINATION_CONFIG[:separator].html_safe.freeze

  # Properties for the "start over" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  # == Usage Notes
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

  # Extract the number of "items" reported by an object.
  #
  # (For aggregate items, this is the number of aggregates as opposed to the
  # number of records from which they are composed.)
  #
  # @param [Api::Record, Model, Array, Hash, *] value
  # @param [*]                                  default
  #
  # @return [Numeric]
  #
  def item_count(value, default: 1)
    result   = (value.size if value.is_a?(Hash) || value.is_a?(Array))
    result ||= value.try(:item_count)   || value.try(:titles).try(:size)
    result ||= value.try(:totalResults) || value.try(:records).try(:size)
    result || default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default results per page for the current controller/action.
  #
  # @return [Integer]
  #
  def default_page_size
    @default_page_size ||= get_page_size
  end

  # Default results per page for the given controller/action.
  #
  # @param [Hash] opt
  #
  # @option opt [Symbol] :controller
  # @option opt [Symbol] :action
  #
  # @return [Integer]
  #
  def get_page_size(**opt)
    opt    = request_parameters.slice(:controller, :action) if opt.blank?
    ctrlr  = opt[:controller].presence
    action = ctrlr && opt[:action].presence
    keys = []
    keys << :"emma.#{ctrlr}.#{action}.pagination.page_size" if action
    keys << :"emma.#{ctrlr}.#{action}.page_size"            if action
    keys << :"emma.#{ctrlr}.pagination.page_size"           if ctrlr
    keys << :"emma.#{ctrlr}.page_size"                      if ctrlr
    keys << :'emma.generic.pagination.page_size'
    keys << :'emma.generic.page_size'
    keys << :'emma.pagination.page_size'
    keys << :'emma.page_size'
    I18n.t(keys.shift, default: keys).to_i
  end

  # Get the number of results per page.
  #
  # @return [Integer]
  #
  def page_size
    @page_size ||= default_page_size
  end

  # Set the number of results per page.
  #
  # @param [Integer] value
  #
  # @return [Integer]
  #
  def page_size=(value)
    @page_size = value&.to_i || default_page_size
  end

  # Get the path to the first page of results.
  #
  # @return [String]                  URL for the first page of results.
  # @return [nil]                     If @first_page is unset.
  #
  def first_page
    @first_page ||= nil
  end

  # Set the path to the first page of results.
  #
  # @param [String, Symbol] value
  #
  # @return [String]                  New URL for the first page of results.
  # @return [nil]                     If @first_page is unset.
  #
  def first_page=(value)
    @first_page = page_path(value)
  end

  # Get the path to the last page of results.
  #
  # @return [String]                  URL for the last page of results.
  # @return [nil]                     If @last_page is unset.
  #
  def last_page
    @last_page ||= nil
  end

  # Set the path to the last page of results.
  #
  # @param [String, Symbol] value
  #
  # @return [String]                  New URL for the last page of results.
  # @return [nil]                     If @last_page is unset.
  #
  def last_page=(value)
    @last_page = page_path(value)
  end

  # Get the path to the next page of results
  #
  # @return [String]                  URL for the next page of results.
  # @return [nil]                     If @next_page is unset.
  #
  def next_page
    @next_page ||= nil
  end

  # Set the path to the next page of results
  #
  # @param [String, Symbol] value
  #
  # @return [String]                  New URL for the next page of results.
  # @return [nil]                     If @next_page is unset.
  #
  def next_page=(value)
    @next_page = page_path(value)
  end

  # Get the path to the previous page of results.
  #
  # @return [String]                  URL for the previous page of results.
  # @return [nil]                     If @prev_page is unset.
  #
  def prev_page
    @prev_page ||= nil
  end

  # Set the path to the previous page of results.
  #
  # @param [String, Symbol] value
  #
  # @return [String]                  New URL for the previous page of results.
  # @return [nil]                     If @prev_page is unset.
  #
  def prev_page=(value)
    @prev_page = page_path(value)
  end

  # Get the offset of the current page into the total set of results.
  #
  # @return [Integer]
  #
  def page_offset
    @page_offset ||= 0
  end

  # Set the offset of the current page into the total set of results.
  #
  # @param [Integer] value
  #
  # @return [Integer]
  #
  def page_offset=(value)
    @page_offset = value.to_i
  end

  # Get the current page of result items.
  #
  # @return [Array]
  #
  def page_items
    @page_items ||= []
  end

  # Set the current page of result items.
  #
  # @param [Array] values
  #
  # @return [Array]
  #
  def page_items=(values)
    @page_items = Array.wrap(values)
  end

  # Get the total results count.
  #
  # @return [Integer]
  #
  def total_items
    @total_items ||= 0
  end

  # Set the total results count.
  #
  # @param [Integer] value
  #
  # @return [Integer]
  #
  def total_items=(value)
    @total_items = value.to_i
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Interpret *value* as a URL path or a JavaScript action.
  #
  # @param [String, Symbol] value     One of [:back, :forward, :go].
  # @param [Integer, nil]   page      Passed to #page_history for *action* :go.
  #
  # @return [String]                  A value usable with 'href'.
  # @return [nil]                     If *value* is invalid.
  #
  def page_path(value, page = nil)
    # noinspection RubyMismatchedArgumentType
    value.is_a?(Symbol) ? page_history(value, page) : value.to_s
  end

  # A value to use in place of a path in order to engage browser history.
  #
  # @param [Symbol]       action      One of [:back, :forward, :go].
  # @param [Integer, nil] page        History page if *directive* is :go.
  #
  # @return [String]
  #
  def page_history(action, page = nil)
    "javascript:history.#{action}(#{page});"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Page number display element.
  #
  # @param [Integer]   page
  # @param [Hash, nil] opt            Options to .page-count wrapper element.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *count* is negative.
  #
  def page_number(page, opt = nil)
    css_selector = '.page-count'
    page         = page.to_i and return if page.negative?
    pages        = get_page_number_label(count: page)&.upcase_first
    html_div("#{pages} #{page}", prepend_classes(opt, css_selector))
  end

  # Page count display element.
  #
  # @param [Integer, nil] count
  # @param [Integer, nil] total
  # @param [String]       unit
  # @param [Hash]         opt         Options to .search-count wrapper element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_count(count, total = nil, unit: nil, **opt)
    css_selector = '.search-count'
    count = positive(count).to_i
    total = positive(total).to_i
    # noinspection RubyMismatchedArgumentType
    total = nil unless total > count
    html_div(prepend_classes!(opt, css_selector)) do
      found = get_page_count_label(count: (total || count), item: unit)
      words = total ? [count, 'of', total, found] : [count, found]
      label = words.map! { |v| number_with_delimiter(v) }.join(' ')
      total ? label : "(#{label})"
    end
  end

  # Placeholder for an item that would have been a link if it had a path.
  #
  # @param [String, Hash, nil] fp     Passed to #pagination_first.
  # @param [String, Hash, nil] pp     Passed to #pagination_prev.
  # @param [String, Hash, nil] np     Passed to #pagination_next.
  # @param [String, nil]       sep    Passed to #pagination_separator.
  # @param [Hash]              opt    For .pagination-controls container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_controls(fp: nil, pp: nil, np: nil, sep: nil, **opt)
    css_selector = '.pagination-controls'
    html_tag(:nav, prepend_classes!(opt, css_selector)) do
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

  # Page number label for the given controller/action.
  #
  # @param [Symbol]  controller       Default: `params[:controller]`.
  # @param [Hash]    opt              Passed to #config_lookup.
  #
  # @return [String]                  The specified value.
  # @return [nil]                     No non-empty value was found.
  #
  def get_page_number_label(controller: nil, **opt)
    controller ||= request_parameters[:controller]
    # noinspection RubyMismatchedReturnType
    config_lookup('pagination.page', controller: controller, **opt)
  end

  # Page count label for the given controller/action.
  #
  # @param [Symbol]  controller       Default: `params[:controller]`.
  # @param [Hash]    opt              Passed to #config_lookup; in particular:
  #
  # @option opt [Integer] :count
  #
  # @return [String]                  The specified value.
  # @return [nil]                     No non-empty value was found.
  #
  def get_page_count_label(controller: nil, **opt)
    controller ||= request_parameters[:controller]
    # noinspection RubyMismatchedReturnType
    config_lookup('pagination.count', controller: controller, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # pagination_separator
  #
  # @param [String, nil] content      Default: `#PAGINATION_SEPARATOR`.
  # @param [Hash]        opt
  #
  # @see #html_span
  #
  def pagination_separator(content = nil, **opt)
    css_selector = '.separator'
    html_span(prepend_classes!(opt, css_selector)) do
      content || PAGINATION_SEPARATOR
    end
  end

  # pagination_first
  #
  # @param [String, Hash, nil] path   Default: `#first_page`.
  # @param [Hash]              opt
  #
  # @see #pagination_control
  #
  def pagination_first(path = nil, **opt)
    css_selector   = '.first'
    path         ||= first_page
    opt[:prefix] ||= pagination_first_icon
    pagination_control(FIRST_PAGE, path, **append_classes!(opt, css_selector))
  end

  # pagination_prev
  #
  # @param [String, Hash, nil] path   Default: `#prev_page`.
  # @param [Hash]              opt
  #
  # @see #pagination_control
  #
  def pagination_prev(path = nil, **opt)
    css_selector   = '.prev'
    path         ||= prev_page
    opt[:prefix] ||= pagination_prev_icon
    opt[:rel]    ||= 'prev'
    pagination_control(PREV_PAGE, path, **append_classes!(opt, css_selector))
  end

  # pagination_next
  #
  # @param [String, Hash, nil] path   Default: `#next_page`.
  # @param [Hash]              opt
  #
  # @see #pagination_control
  #
  def pagination_next(path = nil, **opt)
    css_selector   = '.next'
    path         ||= next_page
    opt[:suffix] ||= pagination_next_icon
    opt[:rel]    ||= 'next'
    pagination_control(NEXT_PAGE, path, **append_classes!(opt, css_selector))
  end

  # pagination_last
  #
  # @param [String, Hash, nil] path   Default: `#last_page`.
  # @param [Hash]              opt
  #
  # @see #pagination_control
  #
  def pagination_last(path = nil, **opt)
    css_selector   = '.last'
    path         ||= last_page
    opt[:suffix] ||= pagination_last_icon
    pagination_control(LAST_PAGE, path, **append_classes!(opt, css_selector))
  end

  # A pagination control link or a non-actionable placeholder if *path* is not
  # valid.
  #
  # @param [String, Hash]      label
  # @param [String, Hash, nil] path
  # @param [Hash]              opt    Passed to #link_to or <span> except for:
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
      html_span(label, append_classes!(opt, 'disabled'))
    end
  end

  # pagination_first_icon
  #
  # @param [Hash] opt
  #
  # @see #pagination_icon
  #
  def pagination_first_icon(**opt)
    pagination_icon(**prepend_classes!(opt, 'square-icon'))
  end

  # pagination_prev_icon
  #
  # @param [Hash] opt
  #
  # @see #pagination_icon
  #
  def pagination_prev_icon(**opt)
    pagination_icon(**prepend_classes!(opt, 'left-triangle-icon'))
  end

  # pagination_next_icon
  #
  # @param [Hash] opt
  #
  # @see #pagination_icon
  #
  def pagination_next_icon(**opt)
    pagination_icon(**prepend_classes!(opt, 'right-triangle-icon'))
  end

  # pagination_last_icon
  #
  # @param [Hash] opt
  #
  # @see #pagination_icon
  #
  def pagination_last_icon(**opt)
    pagination_icon(**prepend_classes!(opt, 'square-icon'))
  end

  # A decorative visual representation of a control action.
  #
  # @param [String, nil] content
  # @param [Hash]        opt
  #
  # @see #html_span
  #
  def pagination_icon(content = nil, **opt)
    opt[:'aria-hidden'] = true unless opt.key?(:'aria-hidden')
    html_span((content || ''), prepend_classes!(opt, 'icon'))
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
