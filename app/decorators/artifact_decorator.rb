# app/decorators/artifact_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/artifact" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Bs::Record::ArtifactMetadata]
#
class ArtifactDecorator < BookshareDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for artifact: Bs::Record::ArtifactMetadata, and: Artifact

  # ===========================================================================
  # :section: Definitions shared with ArtifactsDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BookshareDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include BookshareDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render a metadata listing of an artifact.
    #
    # @param [Hash, nil] pairs        Additional field mappings.
    # @param [Hash]      opt          Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def details(pairs: nil, **opt)
      opt[:pairs] = model_show_fields.merge(pairs || {})
      super(**opt)
    end

    # Render a single entry for use within a list of items.
    #
    # @param [Hash, nil] pairs        Additional field mappings.
    # @param [Hash]      opt          Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def list_item(pairs: nil, **opt)
      opt[:pairs] = model_index_fields.merge(pairs || {})
      super(**opt)
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of artifact instances.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu(**opt)
      opt[:user] ||= :all
      super(**opt)
    end

  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module SharedInstanceMethods

    include BookshareDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods

    # =========================================================================
    # :section: BookshareDecorator::SharedGenericMethods overrides
    # =========================================================================

    public

    # This is a kludge
    #
    # @param [Model, nil] item
    # @param [Hash]       opt       Passed to ArtifactDecorator#download_links
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def artifact_links(item = nil, **opt)
      if item&.respond_to?(:download_links)
        item.download_links(**opt)
      elsif item
        super(item, **opt)
      else
        download_links(**opt)
      end
    end

  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module SharedClassMethods
    include BookshareDecorator::SharedClassMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module SharedDefinitions
    def self.included(base)
      base.include(SharedInstanceMethods)
      base.extend(SharedClassMethods)
    end
  end

end

class ArtifactDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for Bookshare download control properties.
  #
  # @type [Hash{Symbol=>*}]
  #
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create an element containing a link to download the given item.
  #
  # @param [String, Bs::Record::Format, nil] format
  # @param [String, nil]                     url      Def: derived from *item*.
  # @param [String]                          css      Characteristic CSS class.
  # @param [Hash]                            opt      Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]   The HTML link element.
  # @return [nil]                         No link URL was provided or found.
  #
  def artifact_link(format, url: nil, css: '.artifact.inline-popup', **opt)
    repo = cfg = nil
    if object.is_a?(Bs::Api::Record)
      repo  = 'bookshare'
      type  = BsFormatType
      type  = BsPeriodicalFormat if object.class.name&.include?('Periodical')
      fmt   = format&.to_s || type.default
      cfg   = "emma.bookshare.type.#{type}.#{fmt}"
      url ||= h.bs_download_path(bookshareId: object.identifier, fmt: fmt)
    elsif object.is_a?(Search::Api::Record)
      repo  = object.emma_repository || EmmaRepository.default
      fmt   = format&.to_s || object.dc_format
      cfg   = "emma.repository.#{repo}.download_fmt.#{fmt}"
      url ||= object.record_download_url
      url &&= h.bs_retrieval_path(url: url)
    end
    return if url.blank?

    fmt_name  = format.is_a?(Bs::Record::Format) ? format.label : object.label
    fmt_name  = I18n.t(cfg, default: fmt_name)
    repo_name = EmmaRepository.pairs[repo]

    # Initialize link options.
    opt[:label] ||= fmt_name
    opt[:path]    = url

    # Set up the tooltip to be shown before the item has been requested.
    tip_key =
      if !has_class?(opt, 'disabled', 'sign-in-required')
        'emma.download.link.tooltip'
      elsif !h.signed_in?
        'emma.download.link.sign_in.tooltip'
      else
        'emma.download.link.disallowed.tooltip'
      end
    tip_opt = { repo: repo_name, fmt: format_label(fmt_name) }
    opt[:title] = I18n.t(tip_key, **tip_opt, default: DOWNLOAD_TOOLTIP)

    # The tooltip to be shown when the item is actually available for download.
    tip_key = 'emma.download.link.complete.tooltip'
    tip_opt = { button: DOWNLOAD_BUTTON_LABEL, default: DOWNLOAD_COMPLETE_TIP }
    opt[:'data-complete-tooltip'] = I18n.t(tip_key, **tip_opt)

    # The link itself.
    append_css!(opt, 'link')
    parts = [model_link(object, **opt)]

    # Auxiliary control elements which are initially hidden.
    h_opt = { class: 'hidden' }
    parts << download_progress(**h_opt)
    parts << download_button(fmt: fmt_name, **h_opt)
    parts << download_failure(**h_opt)

    # Emit the link and control elements.
    html_div(*parts, class: css_classes(css))
  end

  # Create links to download each artifact of the given item.
  #
  # @param [String] fmt               One of `BsFormatType#values`
  # @param [String] separator
  # @param [Hash]   opt               Passed to #artifact_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_links(fmt: nil, separator: DEFAULT_ELEMENT_SEPARATOR, **opt)
    unless can?(:download)
      added_css = (h.signed_in?) ? 'disabled' : 'sign-in-required'
      append_css!(opt, added_css)
    end
    if object.respond_to?(:formats)
      # === Bs::Api::Record ===
      fmts = Array.wrap(object.formats).compact.uniq
      fmts.select! { |f| f.formatId == fmt } if fmt
      fmts.sort_by!(&:formatId)
    else
      # === Search::Api::Record ===
      fmts = [fmt] # Note that *nil* is acceptable in this case.
    end
    links = fmts.map { |f| artifact_link(f, **opt) }.compact
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
  # @param [String, Symbol, nil] fmt
  # @param [String]              css    Characteristic CSS class/selector.
  # @param [Hash]                opt    Passed to LinkHelper#make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_button(label: nil, fmt: nil, css: DOWNLOAD_BUTTON_CLASS, **opt)
    label       ||= DOWNLOAD_BUTTON_LABEL
    fmt           = format_label(fmt)
    opt[:title] ||= I18n.t('emma.download.button.tooltip', fmt: fmt)
    opt[:role]  ||= 'button'
    prepend_css!(opt, css)
    # noinspection RubyMismatchedArgumentType
    make_link(label, '#', **opt)
  end

  # ===========================================================================
  # :section: BookshareDecorator overrides
  # ===========================================================================

  protected

  # form_action_link
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_action_link(**opt)
    # noinspection RailsParamDefResolve
    opt[:bookshareId] ||= context[:bookshareId] || object.try(:bookshareId)
    opt[:fmt]         ||= context[:fmt]         || object.try(:fmt)
    super(**opt)
  end

  # form_action_description
  #
  # @param [Symbol] action
  #
  # @return [String]
  #
  def form_action_description(action: nil, **)
    (action == :new) ? 'upload' : super # TODO: I18n
  end

  # form_target_description
  #
  # @param [Symbol] action
  #
  # @return [String]
  #
  def form_target_description(action: nil, **)
    case action
      when :edit, :delete then 'artifact metadata' # TODO: I18n
      else                     'an artifact'       # TODO: I18n
    end
  end

end

__loading_end(__FILE__)
