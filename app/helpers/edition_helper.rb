# app/helpers/edition_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/edition" pages.
#
module EditionHelper

  include BookshareHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.
  #
  # @type [String]
  #
  EDITION_SHOW_TOOLTIP = I18n.t('emma.edition.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #model_link except for:
  #
  # @option opt [String] :editionId
  # @option opt [String] :edition       Alias for :editionId
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edition_link(item, **opt)
    local, opt = partition_hash(opt, :editionId, :edition)
    if (eid = local.values.first).present?
      opt[:path]    = "#edition-#{eid}" # TODO: edition show page?
    else
      opt[:no_link] = true
    end
    opt[:tooltip] = EDITION_SHOW_TOOLTIP
    model_link(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Bs::Api::Record] item
  # @param [Any]             value
  # @param [Hash]            opt        Passed to the render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  # @see BookshareHelper#bookshare_render_value
  #
  def edition_render_value(item, value, **opt)
    bookshare_render_value(item, value, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing of an edition.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_details.
  #
  def edition_details(item, pairs: nil, **opt)
    opt[:model] = model = :edition
    opt[:pairs] = Model.show_fields(model).merge(pairs || {})
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
  def edition_list_item(item, pairs: nil, **opt)
    opt[:model] = model = :edition
    opt[:pairs] = Model.index_fields(model).merge(pairs || {})
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
