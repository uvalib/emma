# app/helpers/search_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting access and linkages to the "EMMA Unified Search" API.
#
# noinspection DuplicatedCode
module SearchHelper

  def self.included(base)
    __included(base, '[SearchHelper]')
  end

  include PaginationHelper
  include LogoHelper
  include ModelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  SEARCH_CONFIGURATION = model_configuration('emma.search').deep_freeze
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
    case field_category(value)
      when :dc_title                then title_and_source_logo(item)
      when :emma_repositoryRecordId then source_record_link(item)
      when :emma_retrievalLink      then source_retrieval_link(item)
      else                               render_value(item, value)
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
        if FileNaming::LOCAL_DOWNLOADS
          __debug { "#{__method__} => #{result.inspect}" }
          info = file_info(item, path: url)
          result << info if info.present?
        end
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
  def search_item_details(item, **opt)
    item_details(item, :search, SEARCH_SHOW_FIELDS.merge(opt))
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
  def search_list_entry(item, **opt)
    item_list_entry(item, :search, SEARCH_INDEX_FIELDS.merge(opt))
  end

  # Include edit and delete controls below the entry number.
  #
  # @param [Model] item
  # @param [Hash]  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see ModelHelper#list_entry_number
  # @see UploadHelper#edit_entry_icon
  # @see UploadHelper#delete_entry_icon
  #
  def search_list_entry_number(item, **opt)
    list_entry_number(item, **opt) do
      [edit_entry_icon(item), delete_entry_icon(item) ]
    end
  end

end

__loading_end(__FILE__)
