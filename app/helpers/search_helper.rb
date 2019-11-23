# app/helpers/search_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search'

# Methods supporting access and linkages to the "EMMA Federated Search" API.
#
module SearchHelper

  def self.included(base)
    __included(base, '[SearchHelper]')
  end

  # Include now so that future includes will not override the overrides which
  # are defined in this module.
  include BookshareHelper

  # NOTE: From TitleHelper:
  include PaginationHelper
  include ResourceHelper
  #include ArtifactHelper
  #include ImageHelper

  include Search::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA Federated Search service.
  #
  # @return [SearchService]
  #
  # This method overrides:
  # @see BookshareHelper#api
  #
  def api
    @search_api ||= api_update
  end

  # Update the EMMA Federated Search service.
  #
  # @param [Hash] opt
  #
  # @return [SearchService]
  #
  # This method overrides:
  # @see BookshareHelper#api_update
  #
  def api_update(**opt)
    default_opt = {}
    default_opt[:user]     = current_user if current_user.present?
    default_opt[:no_raise] = true         if Rails.env.test?
    # noinspection RubyYardReturnMatch
    @search_api = SearchService.update(**opt.reverse_merge(default_opt))
  end

  # Remove the EMMA Federated Search service.
  #
  # @return [nil]
  #
  # This method overrides:
  # @see BookshareHelper#api_clear
  #
  def api_clear
    @search_api = SearchService.clear
  end

  # Indicate whether the latest EMMA Federated Search request generated an
  # exception.
  #
  # This method overrides:
  # @see BookshareHelper#api_error?
  #
  def api_error?
    defined?(@search_api) && @search_api.present? && @search_api.error?
  end

  # Get the current EMMA Federated Search exception message if the service has
  # been started.
  #
  # @return [String]
  # @return [nil]
  #
  # This method overrides:
  # @see BookshareHelper#api_error_message
  #
  def api_error_message
    @search_api.error_message if defined?(:@search_api) && @search_api.present?
  end

  # Get the current EMMA Federated Search exception if the service has been
  # started.
  #
  # @return [Exception]
  # @return [nil]
  #
  # This method overrides:
  # @see BookshareHelper#api_exception
  #
  def api_exception
    @search_api.exception if defined?(:@search_api) && @search_api.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of record search results.
  #
  # @return [Array<Search::Record::MetadataRecord>]
  #
  def search_list
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
  SEARCH_SHOW_TOOLTIP = I18n.t('emma.search.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # @param [Search::Api::Record] item
  # @param [Symbol, String, nil] label  Default: `item.label`.
  # @param [Hash]                opt    Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_item_link(item, label = nil, **opt)
    path = search_path(id: item.identifier)
    opt  = opt.merge(tooltip: SEARCH_SHOW_TOOLTIP)
    item_link(item, label, path, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Search::Api::Record] item
  # @param [Object]              value
  #
  # @return [Object]
  #
  # @see ResourceHelper#render_value
  #
  def search_render_value(item, value)
    case field_category(value)
      when :emma_repositoryRecordId then record_link(item)
      when :emma_retrievalLink      then retrieval_link(item)
      else                               render_value(item, value)
    end
  end

  # Make a clickable link to the display page for the title on the originating
  # repository's web site.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def record_link(item, **opt)
    src = item.emma_repository
    id  = CGI.unescape(item.emma_repositoryRecordId)
    url =
      case src
        when 'bookshare'       then bookshare_title_url(item)
        when 'hathiTrust'      then ht_title_url(item)
        when 'internetArchive' then ia_title_url(item)
      end
    return ERB::Util.h(id) unless url.present?
    html_opt = {
      target: '_blank',
      title:  "View this item on the #{src.titleize} website." # TODO: I18n
    }.merge(opt)
    make_link(id, url, **html_opt)
  end

  # Make a clickable link to retrieve a remediated file.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def retrieval_link(item, **opt)
    src = item.emma_repository
    fmt = item.dc_format.upcase
    url = item.emma_retrievalLink.presence
    url ||=
      case src
        when 'bookshare'       then bookshare_download_url(item)
        when 'hathiTrust'      then ht_download_url(item)
        when 'internetArchive' then ia_download_url(item)
      end
    return unless url.present?
    html_opt = {
      target: '_blank',
      title:  "Retrieve the #{fmt} source from #{src.titleize}." # TODO: I18n
    }.merge(opt)
    make_link(CGI.unescape(url), url, **html_opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Fields from Search::Record::MetadataRecord.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # Compare with:
  # @see TitleHelper#TITLE_SHOW_FIELDS
  #
  SEARCH_SHOW_FIELDS = {
    Title:                :dc_title,
    Creator:              :dc_creator,
    Language:             :dc_language,
    Type:                 :dc_type,
    Format:               :dc_format,
    Description:          :dc_description,
    Publisher:            :dc_publisher,
    Subject:              :dc_subject,
    Rights:               :dc_rights,
    Provenance:           :dc_provenance,
    Identifier:           :dc_identifier,
    Related:              :dc_relation,
    DateReceived:         :dcterms_dateAccepted,
    CopyrightDate:        :dcterms_dateCopyright,
    RecordId:             :emma_recordId,
    TitleId:              :emma_titleId,
    Repository:           :emma_repository,
    Collection:           :emma_collection,
    RepositoryRecordId:   :emma_repositoryRecordId,
    RetrievalLink:        :emma_retrievalLink,
    LastUpdate:           :emma_lastRemediationDate,
    UpdateNote:           :emma_lastRemediationNote,
    FormatVersion:        :emma_formatVersion,
    FormatFeature:        :emma_formatFeature,
    AccessibilityFeature: :s_accessibilityFeature,
    AccessibilityControl: :s_accessibilityControl,
    AccessibilityHazard:  :s_accessibilityHazard,
    AccessMode:           :s_accessMode,
    AccessModeSufficient: :s_accessModeSufficient,
    AccessibilityAPI:     :s_accessibilityAPI,
    AccessibilitySummary: :s_accessibilitySummary,
  }.freeze

  # Render an item metadata listing.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_item_details(item, **opt)
    item_details(item, :search, SEARCH_SHOW_FIELDS.merge(opt))
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Fields from Search::Record::MetadataRecord.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  SEARCH_INDEX_FIELDS = SEARCH_SHOW_FIELDS

  # Render a single entry for use within a list of items.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_list_entry(item, **opt)
    item_list_entry(item, :search, SEARCH_INDEX_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
