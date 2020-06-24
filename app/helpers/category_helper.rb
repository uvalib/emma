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
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* is blank.
  #
  def category_details(item, opt = nil)
    pairs = CATEGORY_SHOW_FIELDS.merge(opt || {})
    item_details(item, :category, pairs)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def category_list_entry(item, opt = nil)
    pairs = CATEGORY_INDEX_FIELDS
    opt ||= {}
    item_list_entry(item, :category, row: opt[:row]) do
      # noinspection RubyResolve
      pairs.merge(category_link(item) => "(#{item.titleCount})").merge(opt)
    end
  end

end

__loading_end(__FILE__)
