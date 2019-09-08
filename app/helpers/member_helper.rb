# app/helpers/member_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# MemberHelper
#
module MemberHelper

  def self.included(base)
    __included(base, '[MemberHelper]')
  end

  include GenericHelper
  include PaginationHelper
  include ResourceHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of member results.
  #
  # @return [Array<Api::UserAccount>]
  #
  def member_list
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
  MEMBER_SHOW_TOOLTIP = I18n.t('emma.member.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # NOTE: Over-encoded to allow ID's with '.' to be passed to Rails.
  #
  # @param [Api::Record::Base]   item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash]                opt    Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_link(item, label = nil, **opt)
    path = member_path(id: url_escape(item.identifier))
    opt  = opt.merge(tooltip: MEMBER_SHOW_TOOLTIP)
    item_link(item, label, path, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Fields from Api::UserAccount and ApiMyAccountSummary.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  MEMBER_SHOW_FIELDS = {
    Name:               :name,
    Username:           :username,
    EmailAddress:       :emailAddress,
    PhoneNumber:        :phoneNumber,
    Address:            :address,
    DateOfBirth:        :dateOfBirth,
    Language:           :language,
    SubscriptionStatus: :subscriptionStatus,
    HasAgreement:       :hasAgreement,
    ProofOfDisability:  :proofOfDisabilityStatus,
    CanDownload:        :canDownload,
    AllowAdultContent:  :allowAdultContent,
    Deleted:            :deleted,
    Locked:             :locked,
    Guardian:           :guardian,
    Site:               :site,
    Roles:              :roles,
    Links:              :links, # TODO: subscriptions; pod
  }.freeze

  # Render an item metadata listing.
  #
  # @param [Api::Record::Base] item
  # @param [Hash]              opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_details(item, **opt)
    item_details(item, :member, MEMBER_SHOW_FIELDS.merge(opt))
  end

  # Fields from ApiMyAccountPreferences.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  MEMBER_PREFERENCE_FIELDS = {
    AllowAdultContent:       :allowAdultContent,
    ShowAllBooks:            :showAllBooks,
    UseUEB:                  :useUeb,
    PreferredBrailleFormat:  :brailleFormat,
    BrailleCellLineWidth:    :brailleCellLineWidth,
    PreferredDownloadFormat: :fmt,
    PreferredLanguage:       :language,
  }.freeze

  # Render a listing of member preferences.
  #
  # @param [Api::Record::Base] item
  # @param [Hash]              opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #render_field_values
  #
  def member_preference_values(item, **opt)
    render_field_values(item, model: :member) do
      MEMBER_PREFERENCE_FIELDS.merge(opt)
    end
  end

  # Fields from Api::TitleDownload.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  MEMBER_HISTORY_FIELDS = {
    DateDownloaded: :dateDownloaded,
    Title:          :title,
    Authors:        :authors,
    Format:         :fmt,
    Status:         :status,
    DownloadedBy:   :downloadedBy,
    DownloadedFor:  :downloadedFor,
  }.freeze

  # Render of list of member activity entries.
  #
  # @param [Api::Record::Base, Array<Api::TitleDownload>] item
  # @param [Hash] opt                 Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #render_field_values
  #
  def member_history(item, **opt)
    item  = item.titleDownloads if item.respond_to?(:titleDownloads)
    pairs = MEMBER_HISTORY_FIELDS.merge(opt)
    index = 0
    Array.wrap(item).map { |entry|
      index += 1
      entry_pairs = pairs.merge(index: index)
      content_tag(:div, class: 'history-entry') do
        render_field_values(entry, model: :member, pairs: entry_pairs)
      end
    }.join("\n").html_safe
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Fields from Api::UserAccount and ApiMyAccountSummary.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  MEMBER_INDEX_FIELDS = {
    Name:  :member_link,
    Roles: :roles
  }.freeze

  # Render a single entry for use within a list of items.
  #
  # @param [Api::Record::Base] item
  # @param [Hash]              opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_list_entry(item, **opt)
    item_list_entry(item, :member, MEMBER_INDEX_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
