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

  include ResourceHelper
  include PaginationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of member results.
  #
  # @return [Array<Api::UserAccount>]
  #
  def member_list
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
  # @param [Object]              item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash, nil]           opt    Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_link(item, label = nil, **opt)
    path = member_path(id: url_escape(item.identifier))
    opt  = opt.merge(tooltip: MEMBER_SHOW_TOOLTIP)
    item_link(item, label, path, **opt)
  end

  # ===========================================================================
  # :section:
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

  # member_field_values
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         opt
  #
  # @return [Hash{Symbol=>Object}]
  #
  def member_field_values(item, **opt)
    field_values(item, MEMBER_SHOW_FIELDS.merge(opt))
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

  # member_preference_values
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         opt
  #
  # @return [Hash{Symbol=>Object}]
  #
  def member_preference_values(item, **opt)
    field_values(item, MEMBER_PREFERENCE_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
