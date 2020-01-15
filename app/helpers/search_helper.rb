# app/helpers/search_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

=begin
require 'search'
=end

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

  include PaginationHelper
  include ResourceHelper
  include FileFormatHelper
  include LogoHelper

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
  # @param [Hash]                opt    Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_item_link(item, **opt)
    opt[:path]    = search_path(id: item.identifier)
    opt[:tooltip] = SEARCH_SHOW_TOOLTIP
    item_link(item, **opt)
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

=begin
  # Generic source repository values.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  REPOSITORY_TEMPLATE = I18n.t('emma.source._template').deep_freeze

  # Repository logo image assets.
  #
  # @type [Hash{String=>String}]
  #
  REPOSITORY_LOGO =
    Search::REPOSITORY.transform_values { |entry| entry[:logo] }
      .stringify_keys
      .deep_freeze
=end

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
=begin
    source = nil unless repository_prefix?(source)
    logo   = REPOSITORY_LOGO[source] || REPOSITORY_TEMPLATE[:logo]
    if logo.present?
      content_tag(:div, title, class: "title #{source}".strip) <<
        repository_source_logo(item, logo: logo)
    else
      title_and_source(item)
    end
=end
    source = '' unless EmmaRepository.values.include?(source)
    logo   = repository_source_logo(source)
    if logo.present?
      content_tag(:div, title, class: "title #{source}".strip) << logo
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
    source = nil unless EmmaRepository.values.include?(source)
    name   = source&.titleize || 'LOGO'
    logo   = name && repository_source(item, source: source, name: name)
    if logo.present?
      content_tag(:div, title, class: "title #{source}".strip) << logo
    else
      ERB::Util.h(title)
    end
  end

  # Make a logo for a repository source.
  #
  # @param [Search::Api::Record, String] item
  # @param [Hash]                        opt    Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see LogoHelper#repository_source_logo
  #
  def repository_source_logo(item, **opt)
    source = opt[:source] || item
    source = source.emma_repository if source.respond_to?(:emma_repository)
    # noinspection RubyYardParamTypeMatch
    super(source, **opt)
=begin
    opt, html_opt = partition_options(opt, :source, :logo)
    source = opt[:source] || item.emma_repository
    source = nil unless repository_prefix?(source)
    logo   = opt[:logo] || REPOSITORY_LOGO[source]
    if logo.present?
      name = source&.titleize
      html_opt[:title] ||= "From #{name}" if name.present? # TODO: I18n
      prepend_css_classes!(html_opt, 'repository', 'logo', source)
      # noinspection RubyYardReturnMatch
      image_tag(asset_path(logo), html_opt)
    else
      html_opt.merge!(source: source) if opt[:source]
      repository_source(item, **html_opt)
    end
=end
  end

  # Make a textual logo for a repository source.
  #
  # @param [Search::Api::Record, String] item
  # @param [Hash]                        opt    Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see LogoHelper#repository_source
  #
  def repository_source(item, **opt)
    source = opt[:source] || item
    source = source.emma_repository if source.respond_to?(:emma_repository)
    # noinspection RubyYardParamTypeMatch
    super(source, **opt)
=begin
    source = nil unless repository_prefix?(source)
    name   = opt[:name] || source&.titleize || 'LOGO'
    if name.present?
      html_opt[:title] ||= "From #{name}" # TODO: I18n
      prepend_css_classes!(html_opt, 'repository', 'name', source)
      content_tag(:div, content_tag(:div, name), html_opt)
    else
      ''.html_safe
    end
=end
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
    url = item.record_title_url
    return ERB::Util.h(id) if url.blank?

    origin = item.emma_repository.titleize
    opt[:title]  ||= "View this item on the #{origin} website." # TODO: I18n
    opt[:target] ||= '_blank'
    make_link(id, url, **opt)
  end

  # Make a clickable link to retrieve a remediated file.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #make_link except for:
  #
  # @option opt [String] :label         Link text (default: the URL).
  # @option opt [String] :url           Overrides `item.record_download_url`.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def source_retrieval_link(item, **opt)
    local, opt = partition_options(opt, :label)
    url = local[:url] || item.record_download_url
    return if url.blank?

    label = local[:label] || CGI.unescape(url)
    opt[:target] ||= '_blank'
    opt[:title]  ||=
      begin
        repo = item.emma_repository.titleize
        fmt  = item.dc_format.upcase
        "Retrieve the #{fmt} source from #{repo}." # TODO: I18n
      end
    make_link(label, url, **opt)
      .tap do |result|
        __debug { "#{__method__} => #{result.inspect}" }
        info = file_info(item, path: url)
        result << info if info.present?
      end
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
    RepositoryRecordId:   :emma_repositoryRecordId,
    RetrievalLink:        :emma_retrievalLink,
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
  SEARCH_INDEX_FIELDS = { Title: :dc_title }.merge(SEARCH_SHOW_FIELDS).freeze

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
