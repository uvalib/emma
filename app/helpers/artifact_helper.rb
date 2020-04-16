# app/helpers/artifact_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ArtifactHelper
#
module ArtifactHelper

  def self.included(base)
    __included(base, '[ArtifactHelper]')
  end

  include ModelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_TOOLTIP = I18n.t('emma.download.tooltip').freeze

  # Default completed link tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_COMPLETE_TIP = I18n.t('emma.download.complete.tooltip').freeze

  # Artifact download progress indicator element CSS class.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_CLASS = 'progress'

  # Artifact download progress indicator tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_TIP = I18n.t('emma.download.progress.tooltip').freeze

  # Artifact download progress indicator relative asset path.
  #
  # @type [String]
  #
  # noinspection RailsI18nInspection
  DOWNLOAD_PROGRESS_ASSET =
    I18n.t(
      'emma.download.progress.image.asset',
      default: ImageHelper::PLACEHOLDER_IMAGE_ASSET
    ).freeze

  # Artifact download progress indicator alt text.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_ALT_TEXT =
    I18n.t('emma.download.progress.image.alt').freeze

  # Artifact download failure message element CSS class.
  #
  # @type [String]
  #
  DOWNLOAD_FAILURE_CLASS = 'failure'

  # Artifact download button element CSS class.
  #
  # @type [String]
  #
  DOWNLOAD_BUTTON_CLASS = 'button'

  # Artifact download button tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_BUTTON_LABEL = I18n.t('emma.download.button.label').freeze

  # Generic reference to format type for label construction.
  #
  # @type [String]
  #
  THIS_FORMAT = I18n.t('emma.placeholder.format').freeze

  # Tooltip text added if the link requires authentication. # TODO: I18n
  #
  # @type [String]
  #
  SIGN_IN = 'SIGN-IN REQUIRED'

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  ARTIFACT_CONFIGURATION = model_configuration('emma.artifact').deep_freeze
  ARTIFACT_INDEX_FIELDS  = ARTIFACT_CONFIGURATION.dig(:index, :fields)
  ARTIFACT_SHOW_FIELDS   = ARTIFACT_CONFIGURATION.dig(:show,  :fields)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of artifact results.
  #
  # @return [Array]
  #
  def artifact_list
    page_items
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create an element containing a link to download the given item.
  #
  # @overload artifact_link(item, format, **opt)
  #   @param [Bs::Api::Record]            item
  #   @param [String, Bs::Record::Format] format
  #   @param [Hash]                       opt     Passed to #item_link.
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload artifact_link(item, format, **opt)
  #   @param [Search::Api::Record]        item
  #   @param [String, nil]                format
  #   @param [Hash]                       opt     Passed to #item_link.
  #   @return [ActiveSupport::SafeBuffer, nil]
  #
  # @option opt [String] :url         Default: derived from *item*.
  #
  def artifact_link(item, format, **opt)
    url      = opt.delete(:url)
    fmt_name = format.is_a?(Bs::Record::Format) ? format.label : item.label
    if item.is_a?(Bs::Api::Record)
      type    = FormatType
      type    = PeriodicalFormatType if item.class.name.include?('Periodical')
      format  = format&.to_s || type.default
      lbl_key = "emma.bookshare.type.#{type}.#{format}"
      url   ||= download_path(bookshareId: item.identifier, fmt: format)
    else # if item.is_a?(Search::Api::Record)
      repo    = item.emma_repository
      format  = format&.to_s || item.dc_format
      lbl_key = "emma.source.#{repo}.download_fmt.#{format}"
      url   ||= item.record_download_url
      url   &&= retrieval_path(url: url)
    end
    return if url.blank?
    fmt_name = I18n.t(lbl_key, default: fmt_name)

    # Initialize link options.
    opt = append_css_classes(opt, 'link')
    opt[:label] ||= fmt_name
    opt[:path]    = url

    # Set up the tooltip to be shown before the item has been requested.
    tip_opt = { default: DOWNLOAD_TOOLTIP }
    if !has_class?(opt, 'disabled')
      tip_opt[:fmt] = format_label(fmt_name)
      tip_key = 'emma.download.link.tooltip'
    elsif !signed_in?
      tip_key = 'emma.download.link.sign_in.tooltip'
    else
      tip_key = 'emma.download.link.disallowed.tooltip'
    end
    opt[:title] = I18n.t(tip_key, **tip_opt)

    # The tooltip to be shown when the item is actually available for download.
    tip_key = 'emma.download.link.complete.tooltip'
    tip_opt = { button: DOWNLOAD_BUTTON_LABEL, default: DOWNLOAD_COMPLETE_TIP }
    opt[:'data-complete_tooltip'] = I18n.t(tip_key, **tip_opt)
    opt[:'data-turbolinks']       = false

    # Emit the link and hidden auxiliary elements.
    content_tag(:div, class: 'artifact') do
      item_link(item, **opt) +
        download_progress(class: 'hidden') +
        download_button(class: 'hidden', fmt: fmt_name) +
        download_failure(class: 'hidden')
    end
  end

  # Create links to download each artifact of the given item.
  #
  # @param [Api::Record] item
  # @param [Hash]        opt          Passed to #artifact_link except for:
  #
  # @option opt [String] :fmt         One of `FormatType#values`
  # @option opt [String] :separator   Default: #DEFAULT_ELEMENT_SEPARATOR.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_links(item, **opt)
    opt, html_opt = partition_options(opt, :fmt, :separator)
    format_id = opt[:fmt].presence
    separator = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    permitted = can?(:download, Artifact)
    append_css_classes!(html_opt, 'disabled') unless permitted
    if item.respond_to?(:formats)
      # === Bs::Api::Record ===
      fmts = Array.wrap(item.formats).compact.uniq
      fmts.select! { |fmt| fmt.formatId == format_id } if format_id
      fmts.sort_by!(&:formatId)
    else
      # === Search::Api::Record ===
      fmts = [format_id] # Note that *nil* is acceptable in this case.
    end
    links = fmts.map { |fmt| artifact_link(item, fmt, **html_opt) }.compact
    if permitted && links.present?
      skip_nav_append('Download Formats' => '#field-Formats') # TODO: I18n
    end
    safe_join(links, separator)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Prepare a format name for use in a tooltip or label.
  #
  # @param [String, nil] fmt
  # @param [String, nil] quote        Quote character; default: '"'.
  #
  # @return [String]
  #
  def format_label(fmt, quote: '"')
    fmt ||= THIS_FORMAT
    case fmt
      when /^".*"$/, /^'.*'$/ then fmt
      when /\S\s\S/           then "#{quote}#{fmt}#{quote}"
      else                         fmt
    end
  end

  # An element to be shown while an artifact is being acquired.
  #
  # @param [String, nil] image        Default: 'loading-balls.gif'
  # @param [Hash]        opt          Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_progress(image: nil, **opt)
    opt = prepend_css_classes(opt, DOWNLOAD_PROGRESS_CLASS)
    opt[:title] ||= DOWNLOAD_PROGRESS_TIP
    opt[:alt]   ||= DOWNLOAD_PROGRESS_ALT_TEXT
    opt[:role]  ||= 'button'
    image       ||= asset_path(DOWNLOAD_PROGRESS_ASSET)
    # noinspection RubyYardReturnMatch
    image_tag(image, opt)
  end

  # An element to indicate failure.
  #
  # @param [Hash] opt                 Passed to #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see appendFailureMessage() in app/assets/javascripts/feature/download.js
  #
  def download_failure(**opt)
    opt = prepend_css_classes(opt, DOWNLOAD_FAILURE_CLASS)
    content_tag(:span, '', opt)
  end

  # An element for direct download of an artifact.
  #
  # @param [String, nil] label
  # @param [String, nil] fmt
  # @param [Hash]        opt          Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_button(label: nil, fmt: nil, **opt)
    label ||= DOWNLOAD_BUTTON_LABEL
    fmt = format_label(fmt)
    opt = prepend_css_classes(opt, DOWNLOAD_BUTTON_CLASS)
    opt[:title] ||= I18n.t('emma.download.button.tooltip', fmt: fmt)
    opt[:role]  ||= 'button'
    make_link(label, '#', **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render an item metadata listing.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* is blank.
  #
  def artifact_details(item, opt = nil)
    pairs = ARTIFACT_SHOW_FIELDS.merge(opt || {})
    item_details(item, :artifact, pairs)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def artifact_list_entry(item, opt = nil)
    pairs = ARTIFACT_INDEX_FIELDS.merge(opt || {})
    item_list_entry(item, :artifact, pairs)
  end

end

__loading_end(__FILE__)
