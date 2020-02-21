# app/helpers/reading_list_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ReadingListHelper
#
module ReadingListHelper

  def self.included(base)
    __included(base, '[ReadingListHelper]')
  end

  include ModelHelper
  include TitleHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  READING_LIST_CONFIGURATION =
    model_configuration('emma.reading_list').deep_freeze
  READING_LIST_INDEX_FIELDS  = READING_LIST_CONFIGURATION.dig(:index, :fields)
  READING_LIST_SHOW_FIELDS   = READING_LIST_CONFIGURATION.dig(:show,  :fields)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Control whether thumbnails are shown for reading list entries.
  #
  # @type [Boolean]
  #
  READING_LIST_THUMBNAIL = true

  # Thumbnail element for the given reading list entry.
  #
  # NOTE: ReadingListTitle does not (currently) include a thumbnail link.
  #
  # While this is still the case, this method will discover the link by
  # explicitly by fetching the catalog item.
  #
  # If #READING_LIST_THUMBNAIL is *false*, this method always returns *nil*.
  #
  # @param [Bs::Record::ReadingListTitle] item
  # @param [Hash]                         opt  Passed to TitleHelper#thumbnail.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no thumbnail.
  #
  # @see TitleHelper#thumbnail
  #
  def rl_thumbnail(item, **opt)
    return if item.blank?
    result = thumbnail(item, **opt)
    return result if result.present?
    item = api.get_title(bookshareId: item.bookshareId, no_raise: true)
    thumbnail(item, **opt)
  end

  unless READING_LIST_THUMBNAIL
    def rl_thumbnail(*)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of reading list results.
  #
  # @return [Array<Bs::Record::ReadingListUserView>]
  #
  def reading_list_list
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
  READING_LIST_SHOW_TOOLTIP = I18n.t('emma.reading_list.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #item_link except for:
  #
  # @option opt [String] :readingListId
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def reading_list_link(item, **opt)
    local, opt = partition_options(opt, :readingListId)
    id = local[:readingListId] || item.identifier
    opt[:path]    = reading_list_path(id: id)
    opt[:tooltip] = READING_LIST_SHOW_TOOLTIP
    item_link(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Show reading list subscriptions.
  #
  # TODO: The API doesn't yet seem to provide useful information here.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #record_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def reading_list_subscriptions(item, **opt)
    subscription = item.respond_to?(:subscription) && item.subscription
    record_links(subscription.links, opt) if subscription&.enabled
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Bs::Api::Record] item
  # @param [Object]          value
  #
  # @return [Object]
  #
  # @see ModelHelper#render_value
  #
  def reading_list_render_value(item, value)
    case field_category(value)
      when :name, :label then reading_list_link(item)
      when :subscription then reading_list_subscriptions(item)
      else                    render_value(item, value)
    end
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
  def reading_list_details(item, **opt)
    item_details(item, :reading_list, READING_LIST_SHOW_FIELDS.merge(opt))
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
  def reading_list_list_entry(item, **opt)
    item_list_entry(item, :reading_list, READING_LIST_INDEX_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
