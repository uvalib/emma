# app/helpers/reading_list_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/reading_list" pages.
#
module ReadingListHelper

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
  READING_LIST_FIELDS =
    Model.configured_fields(:reading_list).deep_freeze
  READING_LIST_INDEX_FIELDS = READING_LIST_FIELDS[:index] || {}
  READING_LIST_SHOW_FIELDS  = READING_LIST_FIELDS[:show]  || {}

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
  # @return [ActiveSupport::SafeBuffer]   HTML image or placeholder element.
  # @return [nil]                         If *item* has no thumbnail.
  #
  # @see TitleHelper#thumbnail
  #
  def rl_thumbnail(item, **opt)
    return if item.blank?
    result = thumbnail(item, **opt)
    return result if result.present?
    item = bs_api.get_title(bookshareId: item.bookshareId, no_raise: true)
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

  # Default link tooltip.
  #
  # @type [String]
  #
  READING_LIST_SHOW_TOOLTIP = I18n.t('emma.reading_list.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #model_link except for:
  #
  # @option opt [String] :readingListId
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def reading_list_link(item, **opt)
    local, opt = partition_hash(opt, :readingListId)
    id = local[:readingListId] || item.identifier
    opt[:path]    = reading_list_path(id: id)
    opt[:tooltip] = READING_LIST_SHOW_TOOLTIP
    model_link(item, **opt)
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
    # noinspection RailsParamDefResolve
    subscription = item.try(:subscription)
    record_links(subscription.links, opt) if subscription&.enabled
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Bs::Api::Record] item
  # @param [*]               value
  # @param [Hash]            opt        Passed to render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  # @see ModelHelper#render_value
  #
  def reading_list_render_value(item, value, **opt)
    case field_category(value)
      when :name, :label then reading_list_link(item, **opt)
      when :subscription then reading_list_subscriptions(item, **opt)
      else                    render_value(item, value, **opt)
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing of a reading list.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_details.
  #
  def reading_list_details(item, pairs: nil, **opt)
    opt[:model] = :reading_list
    opt[:pairs] = READING_LIST_SHOW_FIELDS.merge(pairs || {})
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
  def reading_list_list_item(item, pairs: nil, **opt)
    opt[:model] = :reading_list
    opt[:pairs] = READING_LIST_INDEX_FIELDS.merge(pairs || {})
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
