# app/helpers/pagination_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Pagination support methods.
#
module PaginationHelper

  def self.included(base)
    __included(base, '[PaginationHelper]')
  end

  include HtmlHelper
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Separator between pagination controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PAGINATION_SEPARATOR = I18n.t('emma.pagination.separator').html_safe.freeze

  # Properties for the "start over" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  # == Usage Notes
  # To link to the base search without any search terms (a.k.a. "null search").
  #
  #--
  # noinspection RailsI18nInspection
  #++
  START_OVER = I18n.t('emma.pagination.start_over').symbolize_keys.deep_freeze

  # Properties for the "first page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  FIRST_PAGE = I18n.t('emma.pagination.first_page').symbolize_keys.deep_freeze

  # Properties for the "last page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  LAST_PAGE = I18n.t('emma.pagination.last_page').symbolize_keys.deep_freeze

  # Properties for the "previous page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  PREV_PAGE = I18n.t('emma.pagination.prev_page').symbolize_keys.deep_freeze

  # Properties for the "next page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  NEXT_PAGE = I18n.t('emma.pagination.next_page').symbolize_keys.deep_freeze

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
    opt  = request_parameters.slice(:controller, :action) if opt.blank?
    controller = opt[:controller].presence
    action     = controller && opt[:action].presence
    keys = []
    keys << :"emma.#{controller}.#{action}.pagination.page_size" if action
    keys << :"emma.#{controller}.#{action}.page_size"            if action
    keys << :"emma.#{controller}.pagination.page_size"           if controller
    keys << :"emma.#{controller}.page_size"                      if controller
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
    # noinspection RubyYardParamTypeMatch
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
    page     = page.to_i and return if page.negative?
    pages    = get_page_number_label(count: page)&.upcase_first
    html_opt = prepend_css_classes(opt, 'page-count')
    html_div("#{pages} #{page}", html_opt)
  end

  # Page count display element.
  #
  # @param [Integer]   count
  # @param [Hash, nil] opt            Options to .search-count wrapper element.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *count* is negative.
  #
  def pagination_count(count, opt = nil)
    count    = count.to_i and return if count.negative?
    html_opt = prepend_css_classes(opt, 'search-count')
    found    = get_page_count_label(count: count)
    count    = number_with_delimiter(count)
    html_div("#{count} #{found}", html_opt)
  end

  # Placeholder for an item that would have been a link if it had a path.
  #
  # @param [String, nil] fp           Default: `#first_page`.
  # @param [String, nil] pp           Default: `#prev_page`.
  # @param [String, nil] np           Default: `#next_page`.
  # @param [String, nil] sep          Default: `#PAGINATION_SEPARATOR`.
  # @param [Hash]        opt          Options to .pagination wrapper element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_controls(
    fp:  first_page,
    pp:  prev_page,
    np:  next_page,
    sep: PAGINATION_SEPARATOR,
    **opt
  )
    opt = prepend_css_classes(opt, 'pagination')
    html_tag(:nav, opt) do
      link_opt = { class: 'link', 'data-turbolinks-track': false }
      controls = [
        pagination_control(FIRST_PAGE, fp, **link_opt),
        pagination_control(PREV_PAGE,  pp, **link_opt.merge(rel: 'prev')),
        pagination_control(NEXT_PAGE,  np, **link_opt.merge(rel: 'next'))
      ]
      safe_join(controls, sep)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Page number label for the given controller/action.
  #
  # @param [Symbol]  controller       Default: `params[:controller]`.
  # @param [Hash]    opt              Passed to #i18n_lookup.
  #
  # @return [String]                  The specified value.
  # @return [nil]                     No non-empty value was found.
  #
  def get_page_number_label(controller: nil, **opt)
    controller ||= request_parameters[:controller]
    i18n_lookup(controller, 'pagination.page', **opt)
  end

  # Page count label for the given controller/action.
  #
  # @param [Symbol]  controller       Default: `params[:controller]`.
  # @param [Hash]    opt              Passed to #i18n_lookup; in particular:
  #
  # @option opt [Integer] :count
  #
  # @return [String]                  The specified value.
  # @return [nil]                     No non-empty value was found.
  #
  def get_page_count_label(controller: nil, **opt)
    controller ||= request_parameters[:controller]
    i18n_lookup(controller, 'pagination.count', **opt)
  end

  # A pagination control link or a non-actionable placeholder if *path* is not
  # valid.
  #
  # @param [Hash, String] label
  # @param [String, nil]  path
  # @param [Hash]         opt         Passed to #link_to or <span> element.
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
    if link
      link_to(label, path, opt)
    else
      html_span(label, append_css_classes(opt, 'disabled'))
    end
  end

end

__loading_end(__FILE__)
