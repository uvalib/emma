# app/helpers/pagination_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Pagination values.
#
module PaginationHelper

  def self.included(base)
    __included(base, '[PaginationHelper]')
  end

  include ParamsHelper

  # Default number of results per page if none was specified.
  #
  # @type [Integer]
  #
  # == Implementation Notes
  # This is translated to the API :limit parameter.
  #
  DEFAULT_PAGE_SIZE = I18n.t('emma.pagination.page_size').to_i

  # Label for "start over" pagination control.
  #
  # @type [String]
  #
  # == Usage Notes
  # To link to the base search without any search terms (a.k.a. "null search").
  #
  START_OVER_LABEL = I18n.t('emma.pagination.start_over').freeze

  # Label for "first page" pagination control.
  #
  # @type [String]
  #
  FIRST_PAGE_LABEL = I18n.t('emma.pagination.first_page').freeze

  # Label for "last page" pagination control.
  #
  # @type [String]
  #
  LAST_PAGE_LABEL = I18n.t('emma.pagination.last_page').freeze

  # Label for "previous page" pagination control.
  #
  # @type [String]
  #
  PREV_PAGE_LABEL = I18n.t('emma.pagination.prev_page').freeze

  # Label for "next page" pagination control.
  #
  # @type [String]
  #
  NEXT_PAGE_LABEL = I18n.t('emma.pagination.next_page').freeze

  # Separator between pagination controls.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PAGINATION_SEPARATOR = I18n.t('emma.pagination.separator').html_safe.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default tooltip for item links.
  #
  # @return [String]
  #
  def default_show_tooltip
    ''
  end

  # Default of results per page.
  #
  # @return [Integer]
  #
  def default_page_size
    DEFAULT_PAGE_SIZE
  end

  # Number of results per page.
  #
  # @param [Integer, nil] value       Used only to set @page_size.
  #
  # @return [Integer]
  #
  def page_size(value = nil)
    @page_size = value.to_i unless value.nil?
    @page_size ||= default_page_size
  end

  # URL to first page of results.
  #
  # @param [String, nil] value        Used only to set @first_page.
  #
  # @return [String]
  # @return [nil]                     If @first_page is unset.
  #
  def first_page(value = nil)
    @first_page = value.to_s unless value.nil?
    @first_page ||= nil
  end

  # URL to last page of results.
  #
  # @param [String, nil] value        Used only to set @last_page.
  #
  # @return [String]
  # @return [nil]                     If @last_page is unset.
  #
  def last_page(value = nil)
    @last_page = value.to_s unless value.nil?
    @last_page ||= nil
  end

  # URL to next page of results. # TODO: ???
  #
  # @param [String, nil] value        Used only to set @next_page.
  #
  # @return [String]
  # @return [nil]                     If @next_page is unset.
  #
  def next_page(value = nil)
    @next_page = value.to_s unless value.nil?
    @next_page ||= nil
  end

  # URL to previous page of results. # TODO: session stack?
  #
  # @param [String, nil] value        Used only to set @prev_page.
  #
  # @return [String]
  # @return [nil]                     If @prev_page is unset.
  #
  def prev_page(value = nil)
    @prev_page = value.to_s unless value.nil?
    @prev_page ||= nil
  end

  # Offset of the current page into the total set of results.
  #
  # @param [Integer, nil] value       Used only to set @page_size.
  #
  # @return [Integer]
  #
  def page_offset(value = nil)
    @page_offset = value.to_i unless value.nil?
    @page_offset ||= 0
  end

  # Increase the page offset.
  #
  # @param [Integer] delta
  #
  # @return [Integer]
  #
  def page_offset_increment(delta)
    if (delta = delta.to_i) < 0
      page_offset_decrement(delta.abs)
    else
      @page_offset ||= 0
      @page_offset += delta.to_i
    end
  end

  # Reduce the page offset.
  #
  # @param [Integer] delta
  #
  # @return [Integer]
  #
  def page_offset_decrement(delta)
    if (delta = delta.to_i) < 0
      page_offset_increment(delta.abs)
    elsif @page_offset.to_i <= delta
      @page_offset = 0
    else
      @page_offset -= delta
    end
  end

  # Current page of results.
  #
  # @param [Array<Object>, nil] values  Used only to set @page_items.
  #
  # @return [Array<Object>]
  #
  def page_items(values = nil)
    @page_items = Array.wrap(values) unless values.nil?
    @page_items ||= []
  end

  # Total results count.
  #
  # @param [Integer, nil] value       Used only to set @total_items.
  #
  # @return [Integer]
  #
  def total_items(value = nil)
    @total_items = value.to_i unless value.nil?
    @total_items ||= 0
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
  # @param [Hash, nil]   opt          Options to .pagination wrapper element.
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
    css = Array.wrap(opt[:class]).unshift('pagination').compact.uniq.join(' ')
    content_tag(:div, opt.merge(class: css)) do
      link_opt = { class: 'link' }
      controls = [
        pagination_control(FIRST_PAGE_LABEL, fp, link_opt),
        pagination_control(PREV_PAGE_LABEL,  pp, link_opt.merge(rel: 'prev')),
        pagination_control(NEXT_PAGE_LABEL,  np, link_opt.merge(rel: 'next'))
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
  # @param [String]      label
  # @param [String, nil] path
  # @param [Hash, nil]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def pagination_control(label, path = nil, opt = {})
    if path.present?
      link_to(label, path, opt)
    else
      classes = [opt[:class], 'disabled'].flatten.join(' ').squish
      content_tag(:span, label, opt.merge(class: classes))
    end
  end

end

__loading_end(__FILE__)
