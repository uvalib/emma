# app/helpers/edition_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EditionHelper
#
module EditionHelper

  def self.included(base)
    __included(base, '[EditionHelper]')
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
  EDITION_CONFIGURATION = Model.configuration('emma.edition').deep_freeze
  EDITION_INDEX_FIELDS  = EDITION_CONFIGURATION.dig(:index, :fields)
  EDITION_SHOW_FIELDS   = EDITION_CONFIGURATION.dig(:show,  :fields)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of edition results.
  #
  # @return [Array<Bs::Record::UserAccount>]
  #
  def edition_list
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
  EDITION_SHOW_TOOLTIP = I18n.t('emma.edition.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #item_link except for:
  #
  # @option opt [String] :editionId
  # @option opt [String] :edition       Alias for :editionId
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edition_link(item, **opt)
    local, opt = partition_options(opt, :editionId, :edition)
    if (eid = local.values.first).present?
      opt[:path]    = "#edition-#{eid}" # TODO: edition show page?
    else
      opt[:no_link] = true
    end
    opt[:tooltip] = EDITION_SHOW_TOOLTIP
    item_link(item, **opt)
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
  def edition_details(item, pairs: nil, **opt)
    opt[:model] = :edition
    opt[:pairs] = EDITION_SHOW_FIELDS.merge(pairs || {})
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
  def edition_list_entry(item, pairs: nil, **opt)
    opt[:model] = :edition
    opt[:pairs] = EDITION_INDEX_FIELDS.merge(pairs || {})
    item_list_entry(item, **opt)
  end

end

__loading_end(__FILE__)
