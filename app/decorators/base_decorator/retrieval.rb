# app/decorators/base_decorator/download.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting managed downloads.
#
module BaseDecorator::Download

  include BaseDecorator::Common
  include BaseDecorator::Configuration
  include BaseDecorator::Links

  # ===========================================================================
  # :section:
  # ===========================================================================

  public


  # Configuration for Bookshare download control properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  DOWNLOAD_CONFIG = config_page_section(:download).deep_freeze

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
      ImageHelper::IMAGE_PLACEHOLDER_ASSET

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

  # Artifact probe control CSS class.
  #
  # @type [String]
  #
  DOWNLOAD_PROBE_CLASS = 'probe'

  # Artifact download link element CSS class.
  #
  # @type [String]
  #
  DOWNLOAD_LINK_CLASS = 'download'

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
  THIS_FORMAT = config_page(:image, :placeholder, :format).freeze

  # ===========================================================================
  # :section: RepositoryHelper overrides
  # ===========================================================================

  public

  # Produce a link-like control for the retrieval of an Internet Archive file
  # that utilizes the "Printdisabled Unencrypted Ebook API".
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #download_control
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ia_retrieval_link(url, **opt)
    # noinspection RubyMismatchedReturnType
    download_control(url: url, **opt)
  end

  # Produce a link to retrieve an ACE file that utilizes the Internet Archive
  # "Printdisabled Unencrypted Ebook API".
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #ia_retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ace_retrieval_link(url, **opt)
    ia_retrieval_link(url, **opt)
  end

  # Produce a link to retrieve a file from a BiblioVault collection.
  #
  # @param [String] url
  # @param [Hash]   opt               Passed to #retrieval_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bv_retrieval_link(url, **opt)
    file = url.split('/').last
    url  = '/retrieval?url=%s' % url_escape(url)
    # noinspection RubyMismatchedReturnType
    download_control(url: url, file: file, plain: true, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create an element containing a link-like control to probe for availability
  # of an item for download along with (hidden) elements used during the
  # probing process and to actually download the requested item.
  #
  # @param [Model, nil]          item     Default: `object`.
  # @param [String, nil]         url      Def: derived from *item*.
  # @param [String, nil]         file     Name of the file to download.
  # @param [String, Symbol, nil] format   Def: derived from *item*.
  # @param [Boolean]             plain    If *true*, just the download link.
  # @param [String]              css      Characteristic CSS class.
  # @param [Hash]                opt      Passed to the visible element.
  #
  # @return [ActiveSupport::SafeBuffer]   The HTML link element.
  # @return [nil]                         No link URL was provided or found.
  #
  def download_control(
    item:   nil,
    url:    nil,
    file:   nil,
    format: nil,
    plain:  false,
    css:    '.retrieval',
    **opt
  )
    item    ||= object
    url     ||= item.record_download_url or return
    id        = item.emma_repositoryRecordId
    repo      = item.emma_repository || EmmaRepository.default
    fmt       = (format || item.dc_format).to_sym
    file    ||= (fmt == :daisy) ? "#{id}.#{fmt}.zip" : "#{id}.#{fmt}"
    fmt_name  = config_item(:repository,repo,:download_fmt,fmt) || item.label
    repo_name = EmmaRepository.pairs[repo]

    # Set up the tooltip to be shown before the item has been requested.
    tip_opt = { repo: repo_name, fmt: download_format(fmt_name) }
    tooltip =
      if !has_class?(opt, 'disabled', 'sign-in-required', 'role-failure')
        config_page(:download, :link, :tooltip, **tip_opt)
      elsif !h.signed_in?
        config_page(:download, :link, :sign_in, :tooltip, **tip_opt)
      else
        tip_opt[:role] = current_user&.role&.capitalize
        config_page(:download, :link, :role_failure, :tooltip, **tip_opt)
      end
    opt[:title] = tooltip || DOWNLOAD_TOOLTIP

    # The tooltip to be shown when the item is actually available for download.
    tip_opt = { button: DOWNLOAD_BUTTON_LABEL }
    tooltip = config_page(:download, :link, :complete, :tooltip, **tip_opt)
    opt[:'data-complete-tooltip'] = tooltip || DOWNLOAD_COMPLETE_TIP

    # Emit the link and control elements.
    cls = Array.wrap(css)
    cls << 'inline-popup' unless plain
    html_div(class: css_classes(cls)) do
      parts = []
      if plain
        # The link itself.
        l_opt = append_css(opt, 'download').merge!(label: file, plain: true)
        parts << download_button(fmt: fmt_name, file: file, href: url, **l_opt)

      else
        # The link surrogate.
        parts << download_probe(url, label: file, path: url, **opt)

        # Auxiliary control elements which are initially hidden.
        l_opt = append_css(opt, 'hidden')
        parts << download_progress(class: 'hidden')
        parts << download_button(fmt: fmt_name, file: file, href: url, **l_opt)
      end
      parts << download_failure(class: 'hidden')
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The link-like download probe control.
  #
  # @param [String] url
  # @param [String] label
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_probe(url, label:, css: '.probe', **opt)
    opt[:'data-path'] ||= url.start_with?('probe_') ? url : "probe_#{url}"
    prepend_css!(opt, css)
    html_span(label, **opt)
  end

  # An element to be shown while an artifact is being acquired.
  #
  # @param [String, nil] image        Default: 'loading-balls.gif'
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_progress(image: nil, css: DOWNLOAD_PROGRESS_CLASS, **opt)
    image       ||= asset_path(DOWNLOAD_PROGRESS_ASSET)
    opt[:title] ||= DOWNLOAD_PROGRESS_TIP
    opt[:alt]   ||= DOWNLOAD_PROGRESS_ALT_TEXT
    opt[:role]  ||= 'button'
    prepend_css!(opt, css)
    image_tag(image, opt)
  end

  # An element to indicate failure.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *showFailureMessage()*
  #
  def download_failure(css: DOWNLOAD_FAILURE_CLASS, **opt)
    prepend_css!(opt, css)
    html_span('', opt)
  end

  # An element for direct download of an artifact.
  #
  # @param [String, nil]         label
  # @param [String, nil]         file   File name.
  # @param [String, Symbol, nil] fmt
  # @param [Boolean]             plain  If *true*, no #DOWNLOAD_BUTTON_CLASS.
  # @param [String]              css    Characteristic CSS class/selector.
  # @param [Hash]                opt    Passed to LinkHelper#make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_button(
    label:  nil,
    file:   nil,
    fmt:    nil,
    plain:  false,
    css:    DOWNLOAD_LINK_CLASS,
    **opt
  )
    fmt              = download_format(fmt)
    label          ||= DOWNLOAD_BUTTON_LABEL
    opt[:role]     ||= 'button'
    opt[:title]    ||= config_page(:download, :button, :tooltip, fmt: fmt)
    opt[:download] ||= file if file
    prepend_css!(opt, css)
    prepend_css!(opt, DOWNLOAD_BUTTON_CLASS) unless plain
    make_link('#', label, **opt)
  end

  # Prepare a format name for use in a tooltip or label.
  #
  # @param [String, Symbol, nil] fmt
  #
  # @return [String]
  #
  def download_format(fmt)
    return THIS_FORMAT unless (name = fmt&.to_s)
    name.match?(/\s/) ? quote(name) : name
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
