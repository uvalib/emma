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

  include ResourceHelper
  include PaginationHelper

  # Default link tooltip.
  #
  # @type [String]
  #
  EDITION_SHOW_TOOLTIP = I18n.t('emma.edition.show.tooltip').freeze

  # Default number of results per page if none was specified.
  #
  # @type [Integer]
  #
  DEFAULT_EDITION_PAGE_SIZE = DEFAULT_PAGE_SIZE

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
    EDITION_SHOW_TOOLTIP
  end

  # Default of results per page.
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see PaginationHelper#default_page_size
  #
  def default_page_size
    DEFAULT_EDITION_PAGE_SIZE
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of edition results.
  #
  # @return [Array<Api::UserAccount>]
  #
  def edition_list
    page_items
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Object]              item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash, nil]           opt    @see ResourceHelper#item_link
  #
  # @option opt [String] :editionId
  # @option opt [String] :edition       Alias for :editionId
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edition_link(item, label = nil, **opt)
    keys    = %i[editionId edition]
    edition = opt.slice(*keys).compact.values.first
    opt     = opt.except(*keys)
=begin # TODO: edition show page?
    series  = item.identifier
    path    = edition_path(series, editionId: edition)
=end
    path    = "#edition-#{edition}"
    item_link(item, label, path, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fields from Api::PeriodicalEdition.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  EDITION_SHOW_FIELDS = {
    EditionId:       :editionId,
    EditionName:     :editionName,
    PublicationDate: :publicationDate,
    ExpirationDate:  :expirationDate,
    Formats:         :formats,
    Links:           :links,
  }.freeze

  # edition_field_values
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         opt
  #
  # @return [Hash{Symbol=>Object}]
  #
  def edition_field_values(item, **opt)
    field_values(item) do
      EDITION_SHOW_FIELDS.merge(opt).transform_values do |v|
        case v
          when :formats then download_links(item)
          else               v
        end
      end
    end
  end

end

__loading_end(__FILE__)
