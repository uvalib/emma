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

  include ModelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  CATEGORY_CONFIGURATION = Model.configuration('emma.category').deep_freeze
  CATEGORY_INDEX_FIELDS  = CATEGORY_CONFIGURATION.dig(:index, :fields)
  CATEGORY_SHOW_FIELDS   = CATEGORY_CONFIGURATION.dig(:show,  :fields)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of category results.
  #
  # @return [Array<Bs::Record::CategorySummary>]
  #
  def category_list
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
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # BISAC categories can't be used for searching Bookshare so they are not
  # transformed into links.
  #
  def category_link(item, **opt)
    opt[:tooltip] = CATEGORY_SHOW_TOOLTIP
    unless opt.key?(:no_link) || !item.respond_to?(:bookshare_category)
      opt[:no_link] = true if item.bookshare_category.blank?
    end
    item_link(item, **opt) { |term| title_index_path(categories: term) }
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render an item metadata listing.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #item_details.
  #
  def category_details(item, pairs: nil, **opt)
    opt[:model] = :category
    opt[:pairs] = CATEGORY_SHOW_FIELDS.merge(pairs || {})
    item_details(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #item_list_entry.
  #
  def category_list_entry(item, pairs: nil, **opt)
    opt[:model] = :category
    opt[:pairs] = CATEGORY_INDEX_FIELDS.merge(pairs || {})
    opt[:pairs].reverse_merge!(category_link(item) => "(#{item.titleCount})")
    item_list_entry(item, **opt)
  end

end

__loading_end(__FILE__)
