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

  include LogoHelper
  include ModelHelper
  include PaginationHelper
  include RepositoryHelper
  include UploadHelper

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
  #--
  # noinspection RubyYardParamTypeMatch
  #++
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
  #--
  # noinspection RubyResolve
  #++
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
  #--
  # noinspection RubyResolve
  #++
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
  # @see #bs_link?
  #
  #--
  # noinspection RubyResolve
  #++
  def source_record_link(item, **opt)
    url  = item.record_title_url
    repo = bs_link?(url) ? :bookshare : item.emma_repository.presence&.to_sym
    if repo == EmmaRepository.default
      record_popup(item, **opt)
    elsif url.present?
      repo = repo&.to_s&.titleize || 'source repository'       # TODO: I18n
      opt[:title] ||= "View this item on the #{repo} website." # TODO: I18n
      rid = CGI.unescape(item.emma_repositoryRecordId)
      external_link(rid, url, **opt)
    else
      rid = CGI.unescape(item.emma_repositoryRecordId)
      ERB::Util.h(rid)
    end
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
  # @see #bs_link?
  #
  #--
  # noinspection RubyResolve
  #++
  def source_retrieval_link(item, **opt)
    opt, html_opt = partition_options(opt, :label, :url)
    url = opt[:url] || item.record_download_url
    url = CGI.unescape(url.to_s)
    return if url.blank?

    label = opt[:label] || url.dup

    # Adjust the link depending on whether the current session is permitted to
    # perform the download.
    permitted = can?(:download, Artifact)
    append_css_classes!(html_opt, 'sign-in-required disabled') unless permitted

    # To account for the handful of "EMMA" items that are actually Bookshare
    # items from the "EMMA collection", change the reported repository based on
    # the nature of the URL.
    repo = bs_link?(url) ? :bookshare : item.emma_repository.presence&.to_sym

    # Set up the tooltip to be shown before the item has been requested.
    html_opt[:title] ||=
      if permitted
        fmt     = item.dc_format.to_s.underscore.upcase.tr('_', ' ')
        origin  = repo&.to_s&.titleize || 'the source repository' # TODO: I18n
        "Retrieve the #{fmt} source from #{origin}." # TODO: I18n
      else
        tip_key = (signed_in?) ? 'disallowed' : 'sign_in'
        tip_key = "emma.download.link.#{tip_key}.tooltip"
        fmt     = item.label
        origin  = repo || EmmaRepository.default
        default = ArtifactHelper::DOWNLOAD_TOOLTIP
        I18n.t(tip_key, fmt: fmt, repo: origin, default: default)
      end

    case repo
      when :emma
        emma_retrieval_link(item, label, url, **html_opt)
      when :bookshare
        bs_retrieval_link(item, label, url, **html_opt)
      when :hathiTrust
        ht_retrieval_link(item, label, url, **html_opt)
      when :internetArchive
        ia_retrieval_link(item, label, url, **html_opt)
      else
        Log.error { "#{__method__}: #{repo.inspect}: unexpected" } if repo
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
  #--
  # noinspection RubyResolve
  #++
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
        'data-path': show_upload_path(id: rid, modal: true),
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
    db_id =
      if can?(:edit, Upload)
        if item.respond_to?(:id)
          item.id
        elsif item.respond_to?(:emma_repositoryRecordId)
          # noinspection RubyResolve
          if item.emma_repository == EmmaRepository.default.to_s
            rid = item.emma_repositoryRecordId
            Upload.where(repository_id: rid).first&.id
          end
        end
      end
    list_entry_number(item, opt) do
      # noinspection RubyYardParamTypeMatch
      upload_entry_icons(item, id: db_id) if db_id.present?
    end
  end

end

__loading_end(__FILE__)
