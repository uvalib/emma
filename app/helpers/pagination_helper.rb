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

  include ParamsHelper
  include HtmlHelper

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
  # noinspection RailsI18nInspection
  START_OVER = I18n.t('emma.pagination.start_over').symbolize_keys.deep_freeze

  # Properties for the "first page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  # noinspection RailsI18nInspection
  FIRST_PAGE = I18n.t('emma.pagination.first_page').symbolize_keys.deep_freeze

  # Properties for the "last page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  # noinspection RailsI18nInspection
  LAST_PAGE = I18n.t('emma.pagination.last_page').symbolize_keys.deep_freeze

  # Properties for the "previous page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  # noinspection RailsI18nInspection
  PREV_PAGE = I18n.t('emma.pagination.prev_page').symbolize_keys.deep_freeze

  # Properties for the "next page" pagination control.
  #
  # @type [Hash{Symbol=>String}]
  #
  # noinspection RailsI18nInspection
  NEXT_PAGE = I18n.t('emma.pagination.next_page').symbolize_keys.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default of results per page.
  #
  # @return [Integer]
  #
  def default_page_size
    @default_page_size ||=
      begin
        keys = []
        if defined?(params)
          if (controller = params[:controller]).present?
            if (action = params[:action]).present?
              keys << :"emma.#{controller}.#{action}.pagination.page_size"
              keys << :"emma.#{controller}.#{action}.page_size"
            end
            keys << :"emma.#{controller}.pagination.page_size"
            keys << :"emma.#{controller}.page_size"
            keys << :'emma.generic.pagination.page_size'
            keys << :'emma.generic.page_size'
          end
        end
        keys << :'emma.pagination.page_size'
        I18n.t(keys.shift, default: keys)
      end
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
  # @return [String]
  # @return [nil]                     If @first_page is unset.
  #
  def first_page
    @first_page ||= nil
  end

  # Set the path to the first page of results.
  #
  # @param [String, Symbol] value
  #
  # @return [String]
  # @return [nil]                     If @first_page is unset.
  #
  def first_page=(value)
    @first_page = page_path(value)
  end

  # Get the path to the last page of results.
  #
  # @return [String]
  # @return [nil]                     If @last_page is unset.
  #
  def last_page
    @last_page ||= nil
  end

  # Set the path to the last page of results.
  #
  # @param [String, Symbol] value
  #
  # @return [String]
  # @return [nil]                     If @last_page is unset.
  #
  def last_page=(value)
    @last_page = page_path(value)
  end

  # Get the path to the next page of results
  #
  # @return [String]
  # @return [nil]                     If @next_page is unset.
  #
  def next_page
    @next_page ||= nil
  end

  # Set the path to the next page of results
  #
  # @param [String, Symbol] value
  #
  # @return [String]
  # @return [nil]                     If @next_page is unset.
  #
  def next_page=(value)
    @next_page = page_path(value)
  end

  # Get the path to the previous page of results.
  #
  # @return [String]
  # @return [nil]                     If @prev_page is unset.
  #
  def prev_page
    @prev_page ||= nil
  end

  # Set the path to the previous page of results.
  #
  # @param [String, Symbol] value
  #
  # @return [String]
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

  # Get the current page of results.
  #
  # @return [Array<Object>]
  #
  def page_items
    @page_items ||= []
  end

  # Set the current page of results.
  #
  # @param [Array<Object>] values
  #
  # @return [Array<Object>]
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
  # @return [String]
  # @return [nil]                     If *value* is invalid.
  #
  def page_path(value, page = nil)
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
    content_tag(:div, opt) do
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

  # A pagination control link or a non-actionable placeholder if *path* is not
  # valid.
  #
  # @param [Hash, String] label
  # @param [String, nil]  path
  # @param [Hash]         opt         Passed to #link_to or <span> element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_control(label, path = nil, **opt)
    link = path.present?
    if label.is_a?(Hash)
      prop  = label
      label = prop[:label]
      tip   = link ? prop[:tooltip] : prop.dig(:no_link, :tooltip)
      opt   = opt.merge(title: tip) if tip.present?
    end
    if link
      link_to(label, path, opt)
    else
      content_tag(:span, label, append_css_classes(opt, 'disabled'))
    end
  end

end

__loading_end(__FILE__)
