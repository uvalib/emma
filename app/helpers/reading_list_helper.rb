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

  include TitleHelper

  # ===========================================================================
  # :section: TitleHelper overrides
  # ===========================================================================

  public

  # Control whether thumbnails are shown for reading list entries.
  #
  # @type [Boolean]
  #
  READING_LIST_THUMBNAIL = true

  # Thumbnail element for the given reading list entry.
  #
  # NOTE: Api::ReadingListTitle does not (currently) include a thumbnail link.
  #
  # While this is still the case, this method will discover the link by
  # explicitly by fetching the catalog item.
  #
  # If #READING_LIST_THUMBNAIL is *false*, this method always returns *nil*.
  #
  # @param [Api::ReadingListTitle] item
  # @param [Hash]                  opt    Passed to TitleHelper#thumbnail.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* has no thumbnail.
  #
  # This method overrides:
  # @see TitleHelper#thumbnail
  #
  def thumbnail(item, **opt)
    super || super(@api.get_title(bookshareId: item.bookshareId), **opt)
  end

  unless READING_LIST_THUMBNAIL
    def thumbnail(*)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of reading list results.
  #
  # @return [Array<Api::ReadingListUserView>]
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
  # @param [Api::Record::Base]   item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash]                opt    Passed to #item_link except for:
  #
  # @option opt [String] :readingListId
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def reading_list_link(item, label = nil, **opt)
    html_opt, opt = extract_options(opt, :readingListId)
    id   = opt[:readingListId] || item.identifier
    path = reading_list_path(id: id)
    html_opt[:tooltip] = READING_LIST_SHOW_TOOLTIP
    item_link(item, label, path, **html_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Show reading list subscriptions.
  #
  # TODO: The API doesn't yet seem to provide useful information here.
  #
  # @param [Api::Record::Base] item
  # @param [Hash]              opt    Passed to #record_links.
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

  # Fields from Api::ReadingListUserView.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  READING_LIST_SHOW_FIELDS = {
    Description:    :description,
    Access:         :access,
    Owner:          :owner,
    AssignedBy:     :assignedBy,
    Subscription:   :subscription,
    DateUpdated:    :dateUpdated,
    ReadingListId:  :readingListId,
    MemberCount:    :memberCount,
    TitleCount:     :titleCount,
    Allows:         :allows,
    Links:          :links,
  }.freeze

  # reading_list_field_values
  #
  # @param [Api::Record::Base] item
  # @param [Hash]              opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def reading_list_field_values(item, **opt)
    field_values(item) do
      READING_LIST_SHOW_FIELDS.merge(opt).transform_values do |v|
        case v
          when :subscription then reading_list_subscriptions(item)
          else                    v
        end
      end
    end
  end

end

__loading_end(__FILE__)
