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

  include GenericHelper
  include PaginationHelper
  include ResourceHelper
  include ArtifactHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of edition results.
  #
  # @return [Array<Bs::Record::UserAccount>]
  #
  def edition_list
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
    eid = local.values.first
    opt[:path]    = "#edition-#{eid}" # TODO: edition show page?
    opt[:tooltip] = EDITION_SHOW_TOOLTIP
    item_link(item, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Fields from Bs::Record::PeriodicalEdition.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  EDITION_SHOW_FIELDS = {
    EditionId:       :editionId,
    EditionName:     :editionName,
    PublicationDate: :publicationDate,
    ExpirationDate:  :expirationDate,
    Formats:         :download_links,
    Links:           :links,
  }.freeze

  # Render an item metadata listing.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edition_details(item, **opt)
    item_details(item, :edition, EDITION_SHOW_FIELDS.merge(opt))
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Fields from Bs::Record::PeriodicalEdition.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  EDITION_INDEX_FIELDS = EDITION_SHOW_FIELDS

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edition_list_entry(item, **opt)
    item_list_entry(item, :edition, EDITION_INDEX_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
