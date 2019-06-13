# app/helpers/category_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# CategoryHelper
#
module CategoryHelper

  def self.included(base)
    __included(base, '[CategoryHelper]')
  end

  include ResourceHelper
  include PaginationHelper

  # Default link tooltip.
  #
  # @type [String]
  #
  CATEGORY_SHOW_TOOLTIP = I18n.t('emma.category.show.tooltip').freeze

  # Default number of results per page if none was specified.
  #
  # @type [Integer]
  #
  DEFAULT_CATEGORY_PAGE_SIZE = 20

  # ===========================================================================
  # :section: PaginationHelper overrides
  # ===========================================================================

  public

  # Default tooltip for item links.
  #
  # @return [String]
  #
  # This method overrides:
  # @see PaginationHelper#default_show_tooltip
  #
  def default_show_tooltip
    CATEGORY_SHOW_TOOLTIP
  end

  # Default of results per page.
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see PaginationHelper#default_page_size
  #
  def default_page_size
    DEFAULT_CATEGORY_PAGE_SIZE
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of category results.
  #
  # @return [Array<Api::CategorySummary>]
  #
  def category_list
    page_items
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the catalog title search for the given category.
  #
  # @param [Object]              item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash, nil]           opt    @see ResourceHelper#item_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # BISAC categories can't be used for searching Bookshare so they are not
  # transformed into links.
  #
  def category_link(item, label = nil, **opt)
    unless opt.key?(:no_link) || !item.respond_to?(:categoryType)
      if item.categoryType&.casecmp('bookshare')&.nonzero?
        opt = opt.merge(no_link: true)
      end
    end
    opt = opt.merge(title: CATEGORY_SHOW_TOOLTIP) unless opt.key?(:title)
    item_link(item, label, **opt) { |term| title_index_path(categories: term) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>Symbol}]
  CATEGORY_SHOW_FIELDS = {
    # TODO: ???
  }.freeze

  # category_field_values
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         opt
  #
  # @return [Hash{Symbol=>Object}]
  #
  def category_field_values(item, **opt)
    field_values(item, CATEGORY_SHOW_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
