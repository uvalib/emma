# app/helpers/artifact_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/artifact" pages.
#
module ArtifactHelper

  include ModelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for Bookshare download control properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  DOWNLOAD_CONFIG = I18n.t('emma.download', default: {}).deep_freeze

  # Default link tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_TOOLTIP = DOWNLOAD_CONFIG[:tooltip]

  # Default completed link tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_COMPLETE_TIP = DOWNLOAD_CONFIG.dig(:complete, :tooltip)

  # Artifact download progress indicator element CSS class.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_CLASS = 'progress'

  # Artifact download progress indicator tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_TIP = DOWNLOAD_CONFIG.dig(:progress, :tooltip)

  # Artifact download progress indicator relative asset path.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_ASSET =
    DOWNLOAD_CONFIG.dig(:progress, :image, :asset) ||
      ImageHelper::PLACEHOLDER_IMAGE_ASSET

  # Artifact download progress indicator alt text.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_ALT_TEXT = DOWNLOAD_CONFIG.dig(:progress, :image, :alt)

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

  # Artifact download button label.
  #
  # @type [String]
  #
  DOWNLOAD_BUTTON_LABEL = DOWNLOAD_CONFIG.dig(:button, :label)

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
  ARTIFACT_FIELDS       = Model.configured_fields(:artifact).deep_freeze
  ARTIFACT_INDEX_FIELDS = ARTIFACT_FIELDS[:index] || {}
  ARTIFACT_SHOW_FIELDS  = ARTIFACT_FIELDS[:show]  || {}

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create an element containing a link to download the given item.
  #
  # @param [Api::Record]                     item
  # @param [String, Bs::Record::Format, nil] format
  # @param [String, nil]                     url      Def: derived from *item*.
  # @param [Hash]                            opt      Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]   The HTML link element.
  # @return [nil]                         No link URL was provided or found.
  #
  def artifact_link(item, format, url: nil, **opt)
    # noinspection RubyNilAnalysis
    fmt_name = format.is_a?(Bs::Record::Format) ? format.label : item.label
    if item.is_a?(Bs::Api::Record)
      repo    = 'bookshare'
      type    = BsFormatType
      type    = BsPeriodicalFormat if item.class.name.include?('Periodical')
      format  = format&.to_s || type.default
      lbl_key = "emma.bookshare.type.#{type}.#{format}"
      url   ||= bs_download_path(bookshareId: item.identifier, fmt: format)
    else # if item.is_a?(Search::Api::Record)
      repo    = item.emma_repository || EmmaRepository.default
      format  = format&.to_s || item.dc_format
      lbl_key = "emma.repository.#{repo}.download_fmt.#{format}"
      url   ||= item.record_download_url
      url   &&= bs_retrieval_path(url: url)
    end
    return if url.blank?
    repo_name = EmmaRepository.pairs[repo]
    fmt_name  = I18n.t(lbl_key, default: fmt_name)

    # Initialize link options.
    append_classes!(opt, 'link')
    opt[:label] ||= fmt_name
    opt[:path]    = url

    # Set up the tooltip to be shown before the item has been requested.
    tip_key =
      if !has_class?(opt, 'disabled', 'sign-in-required')
        'emma.download.link.tooltip'
      elsif !signed_in?
        'emma.download.link.sign_in.tooltip'
      else
        'emma.download.link.disallowed.tooltip'
      end
    tip_opt = {
      repo:    repo_name,
      fmt:     format_label(fmt_name),
      default: DOWNLOAD_TOOLTIP
    }
    opt[:title] = I18n.t(tip_key, **tip_opt)

    # The tooltip to be shown when the item is actually available for download.
    tip_key = 'emma.download.link.complete.tooltip'
    tip_opt = { button: DOWNLOAD_BUTTON_LABEL, default: DOWNLOAD_COMPLETE_TIP }
    opt[:'data-complete_tooltip'] = I18n.t(tip_key, **tip_opt)
    opt[:'data-turbolinks']       = false

    # Auxiliary control elements which are initially hidden.
    hidden_opt = { class: 'hidden' }
    hidden = []
    hidden << download_progress(**hidden_opt)
    hidden << download_button(fmt: fmt_name, **hidden_opt)
    hidden << download_failure(**hidden_opt)

    # Emit the link and control elements.
    html_div(class: 'artifact popup-container') do
      model_link(item, **opt) << safe_join(hidden)
    end
  end

  # Create links to download each artifact of the given item.
  #
  # @param [Api::Record] item
  # @param [Hash]        opt          Passed to #artifact_link except for:
  #
  # @option opt [String] :fmt         One of `BsFormatType#values`
  # @option opt [String] :separator   Default: #DEFAULT_ELEMENT_SEPARATOR.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_links(item, **opt)
    opt, html_opt = partition_hash(opt, :fmt, :separator)
    format_id = opt[:fmt].presence
    separator = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    permitted = can?(:download, Artifact)
    unless permitted
      added_class = (signed_in?) ? 'disabled' : 'sign-in-required'
      append_classes!(html_opt, added_class)
    end
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
    safe_join(links, separator)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Prepare a format name for use in a tooltip or label.
  #
  # @param [String, Symbol, nil] fmt
  # @param [String, nil]         quote  Quote character; default: '"'.
  #
  # @return [String]
  #
  def format_label(fmt, quote: '"')
    case (name = fmt&.to_s || THIS_FORMAT)
      when /^".*"$/, /^'.*'$/ then name
      when /\S\s\S/           then "#{quote}#{name}#{quote}"
      else                         name
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
    css_selector  = DOWNLOAD_PROGRESS_CLASS
    image       ||= asset_path(DOWNLOAD_PROGRESS_ASSET)
    opt[:title] ||= DOWNLOAD_PROGRESS_TIP
    opt[:alt]   ||= DOWNLOAD_PROGRESS_ALT_TEXT
    opt[:role]  ||= 'button'
    # noinspection RubyMismatchedReturnType
    image_tag(image, prepend_classes!(opt, css_selector))
  end

  # An element to indicate failure.
  #
  # @param [Hash] opt                 Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *appendFailureMessage*
  #
  def download_failure(**opt)
    css_selector = DOWNLOAD_FAILURE_CLASS
    html_span('', prepend_classes!(opt, css_selector))
  end

  # An element for direct download of an artifact.
  #
  # @param [String, nil]         label
  # @param [String, Symbol, nil] fmt
  # @param [Hash]                opt    Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_button(label: nil, fmt: nil, **opt)
    css_selector  = DOWNLOAD_BUTTON_CLASS
    label       ||= DOWNLOAD_BUTTON_LABEL
    fmt           = format_label(fmt)
    opt[:title] ||= I18n.t('emma.download.button.tooltip', fmt: fmt)
    opt[:role]  ||= 'button'
    # noinspection RubyMismatchedParameterType
    make_link(label, '#', **prepend_classes!(opt, css_selector))
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing of an artifact.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_details.
  #
  def artifact_details(item, pairs: nil, **opt)
    opt[:model] = :artifact
    opt[:pairs] = ARTIFACT_SHOW_FIELDS.merge(pairs || {})
    model_details(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_list_item.
  #
  def artifact_list_item(item, pairs: nil, **opt)
    opt[:model] = :artifact
    opt[:pairs] = ARTIFACT_INDEX_FIELDS.merge(pairs || {})
    model_list_item(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
