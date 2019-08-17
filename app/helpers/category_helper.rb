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

  include PaginationHelper
  include ResourceHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of category results.
  #
  # @return [Array<Api::CategorySummary>]
  #
  def category_list
    # noinspection RubyYardReturnMatch
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
  CATEGORY_SHOW_TOOLTIP = I18n.t('emma.category.show.tooltip').freeze

  # Create a link to the catalog title search for the given category.
  #
  # @param [Api::Record::Base]   item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash]                opt    Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # BISAC categories can't be used for searching Bookshare so they are not
  # transformed into links.
  #
  def category_link(item, label = nil, **opt)
    opt = opt.merge(tooltip: CATEGORY_SHOW_TOOLTIP)
    if !opt.key?(:no_link) && item.respond_to?(:categoryType)
      opt[:no_link] = true if item.categoryType&.casecmp('bookshare')&.nonzero?
    end
    item_link(item, label, **opt) { |term| title_index_path(categories: term) }
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # @type [Hash{Symbol=>Symbol}]
  CATEGORY_SHOW_FIELDS = {
    # TODO: ???
  }.freeze

  # Render an item metadata listing.
  #
  # @param [Api::Record::Base] item
  # @param [Hash]              opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def category_details(item, **opt)
    item_details(item, :category, CATEGORY_SHOW_FIELDS.merge(opt))
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # @type [Hash{Symbol=>Symbol}]
  CATEGORY_INDEX_FIELDS = {
    # TODO: ???
  }.freeze

  # Render a single entry for use within a list of items.
  #
  # @param [Api::Record::Base] item
  # @param [Hash]              opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def category_list_entry(item, **opt)
    item_list_entry(item, :category) do
      CATEGORY_INDEX_FIELDS.merge(
        category_link(item) => "(#{item.titleCount})"
      ).merge(opt)
    end
  end

end

__loading_end(__FILE__)
