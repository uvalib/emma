# app/helpers/search_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search'

# Methods supporting access and linkages to the "EMMA Federated Search" API.
#
# noinspection DuplicatedCode
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
      when :dc_title                then title_and_source_logo(item)
      when :emma_repositoryRecordId then source_record_link(item)
      when :emma_retrievalLink      then source_retrieval_link(item)
      else                               render_value(item, value)
    end
  end

  # Repository logo image assets.
  #
  # @type [Hash{String=>String}]
  #
  REPOSITORY_LOGO =
    REPOSITORY_RAW.transform_values { |entry| entry[:logo] }
      .stringify_keys
      .deep_freeze

  # Display title of the associated work along with the logo of the source
  # repository.
  #
  # @param [Search::Api::Record] item
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_and_source_logo(item)
    title  = item.full_title
    source = item.emma_repository
    logo   = REPOSITORY_LOGO[source]
    if logo.present?
      t_opt = { class: "title logo #{source}" }
      r_opt = { class: "repository logo #{source}" }
      r_opt[:title] = "From #{source.titleize}" # TODO: I18n
      content_tag(:div, title, t_opt) << image_tag(asset_path(logo), r_opt)
    else
      title_and_source(item)
    end
  end

  # Display title of the associated work along with the source repository.
  #
  # @param [Search::Api::Record] item
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_and_source(item)
    title  = item.full_title
    source = item.emma_repository
    source = nil unless Repository.values.include?(source)
    logo   = source&.titleize || 'LOGO'
    if logo.present?
      t_opt = { class: "title name #{source}" }
      r_opt = { class: "repository name #{source}" }
      r_opt[:title] = "From #{logo}" # TODO: I18n
      content_tag(:div, title, t_opt) << content_tag(:div, logo, r_opt)
    else
      ERB::Util.h(title)
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
  def source_record_link(item, **opt)
    id  = CGI.unescape(item.emma_repositoryRecordId)
    url = record_title_url(item)
    if url.present?
      origin   = item.emma_repository.titleize
      html_opt = {
        target: '_blank',
        title:  "View this item on the #{origin} website." # TODO: I18n
      }.merge(opt)
      make_link(id, url, **html_opt)
    else
      ERB::Util.h(id)
    end
  end

  # Make a clickable link to retrieve a remediated file.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def source_retrieval_link(item, **opt)
    url = record_download_url(item)
    return unless url.present?
    format   = item.dc_format.upcase
    origin   = item.emma_repository.titleize
    html_opt = {
      target: '_blank',
      title:  "Retrieve the #{format} source from #{origin}." # TODO: I18n
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
