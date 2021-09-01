# app/helpers/category_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/category" pages.
#
module CategoryHelper

  include ModelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  CATEGORY_FIELDS       = Model.configured_fields(:category).deep_freeze
  CATEGORY_INDEX_FIELDS = CATEGORY_FIELDS[:index] || {}
  CATEGORY_SHOW_FIELDS  = CATEGORY_FIELDS[:show]  || {}

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
  # @param [Hash]            opt      Passed to #model_link.
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
    model_link(item, **opt) { |term| title_index_path(categories: term) }
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing of a category.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_details.
  #
  def category_details(item, pairs: nil, **opt)
    opt[:model] = :category
    opt[:pairs] = CATEGORY_SHOW_FIELDS.merge(pairs || {})
    model_details(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_list_item.
  #
  def category_list_item(item, pairs: nil, **opt)
    opt[:model] = :category
    opt[:pairs] = item ? { category_link(item) => "(#{item.titleCount})" } : {}
    opt[:pairs].merge!(CATEGORY_INDEX_FIELDS)
    opt[:pairs].merge!(pairs) if pairs.present?
    model_list_item(item, **opt)
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
