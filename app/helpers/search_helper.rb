# app/helpers/search_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting access and linkages to the "EMMA Unified Search" API.
#
#--
# noinspection DuplicatedCode
#++
module SearchHelper

  def self.included(base)
    __included(base, '[SearchHelper]')
  end

  include PaginationHelper
  include LogoHelper
  include ModelHelper
  include ArtifactHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  SEARCH_CONFIGURATION = Model.configuration('emma.search').deep_freeze
  SEARCH_INDEX_FIELDS  = SEARCH_CONFIGURATION.dig(:index, :fields)
  SEARCH_SHOW_FIELDS   = SEARCH_CONFIGURATION.dig(:show,  :fields)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of record search results.
  #
  # @return [Array<Search::Record::MetadataRecord>]
  #
  def search_list
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
  # @see ModelHelper#render_value
  #
  def search_render_value(item, value)
    case value
      when :dc_title                then title_and_source_logo(item)
      when :emma_repositoryRecordId then source_record_link(item)
      when :emma_retrievalLink      then source_retrieval_link(item)
      else                               upload_render_value(item, value)
    end
  end

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
    source = '' unless EmmaRepository.values.include?(source)
    logo   = repository_source_logo(source)
    if logo.present?
      # noinspection RubyYardReturnMatch
      html_div(title, class: "title #{source}".strip) << logo
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
      # noinspection RubyYardReturnMatch
      html_div(title, class: "title #{source}".strip) << logo
    else
      ERB::Util.h(title)
    end
  end

  # Make a clickable link to the display page for the title on the originating
  # repository's web site.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #record_popup or #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def source_record_link(item, **opt)
    repo = item.emma_repository
    if repo&.to_sym == EmmaRepository.default
      record_popup(item, **opt)
    elsif (url = item.record_title_url).present?
      repo = repo&.titleize || 'source repository'             # TODO: I18n
      opt[:title] ||= "View this item on the #{repo} website." # TODO: I18n
      rid = CGI.unescape(item.emma_repositoryRecordId)
      external_link(rid, url, **opt)
    else
      rid = CGI.unescape(item.emma_repositoryRecordId)
      ERB::Util.h(rid)
    end
  end

  # HathiTrust download parameters which cause a prompt for login.
  #
  # @type [String]
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  HT_DOWNLOAD_URL_PARAMS = 'urlappend=%3Bsignon=swle:wayf'

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
    opt, html_opt = partition_options(opt, :label, :url)
    url = opt[:url] || item.record_download_url
    url = CGI.unescape(url.to_s)
    return if url.blank?

    label = opt[:label] || url.dup

    # Adjust the link depending on whether the current session is permitted to
    # perform the download.
    permitted = can?(:download, Artifact)
    append_css_classes!(html_opt, 'disabled') unless permitted

    # Set up the tooltip to be shown before the item has been requested.
    html_opt[:title] ||=
      if permitted
        fmt     = item.dc_format.to_s.underscore.upcase.tr('_', ' ')
        repo    = item.emma_repository.to_s.titleize
        "Retrieve the #{fmt} source from #{repo}." # TODO: I18n
      else
        tip_key = (signed_in?) ? 'disallowed' : 'sign_in'
        tip_key = "emma.download.link.#{tip_key}.tooltip"
        fmt     = item.label
        repo    = item.emma_repository || EmmaRepository.default
        default = ArtifactHelper::DOWNLOAD_TOOLTIP
        I18n.t(tip_key, fmt: fmt, repo: repo, default: default)
      end

    case (source = item.emma_repository.presence).to_s
      when 'emma'
        url.sub!(%r{localhost:\d+}, 'localhost') unless application_deployed?
        external_link(label, url, **html_opt)

      when 'bookshare'
        download_links(item, label: label, url: url, **html_opt)

      when 'hathiTrust'
        unless url.include?(HT_DOWNLOAD_URL_PARAMS)
          url << (url.include?('?') ? '&' : '?')
          url << HT_DOWNLOAD_URL_PARAMS
        end
        external_link(label, url, **html_opt)

      when 'internetArchive'
        external_link(label, url, **html_opt) # TODO: internetArchive retrieval

      else
        Log.error { "#{__method__}: #{source.inspect}: unexpected" } if source
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render an item metadata listing.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* is blank.
  #
  def search_item_details(item, opt = nil)
    pairs = SEARCH_SHOW_FIELDS.merge(opt || {})
    item_details(item, :search, pairs)
  end

  # Create a container with the repository ID displayed as a link but acting as
  # a popup toggle button and a popup panel which is initially hidden.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Passed to #popup_container except for:
  #
  # @option opt [Hash] :attr            Options for deferred content.
  #
  # @see togglePopup() in app/assets/javascripts/feature/popup.js
  #
  def record_popup(item, **opt)
    rid = item.emma_repositoryRecordId
    opt = append_css_classes(opt, 'record-popup')
    placeholder_attr = opt.delete(:attr)&.dup || {}
    opt[:'data-iframe'] = placeholder_attr[:id] ||= "record-frame-#{rid}"
    opt[:title] ||= 'View this repository record.' # TODO: I18n
    opt[:control] = { text: ERB::Util.h(rid) }
    popup_container(**opt) do
      placeholder_text = 'Loading record...' # TODO: I18n
      placeholder_opt  = {
        class:       "iframe #{PopupHelper::POPUP_DEFERRED_CLASS}",
        'data-path': upload_path(id: rid, modal: true),
        'data-attr': placeholder_attr.to_json
      }
      html_div(placeholder_text, **placeholder_opt)
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Search::Api::Record] item
  # @param [Hash]                opt    Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_list_entry(item, opt = nil)
    pairs = SEARCH_INDEX_FIELDS.merge(opt || {})
    item_list_entry(item, :search, pairs)
  end

  # Include edit and delete controls below the entry number.
  #
  # @param [Model] item
  # @param [Hash]  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see ModelHelper#list_entry_number
  # @see UploadHelper#upload_edit_icon
  # @see UploadHelper#upload_delete_icon
  #
  def search_list_entry_number(item, opt = nil)
    list_entry_number(item, opt) do
      [upload_edit_icon(item), upload_delete_icon(item)]
    end
  end

end

__loading_end(__FILE__)
