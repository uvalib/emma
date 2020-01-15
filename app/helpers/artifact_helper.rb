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

  include GenericHelper
  include PaginationHelper
  include ResourceHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_TOOLTIP =
    I18n.t('emma.download.tooltip').freeze

  # Default completed link tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_COMPLETE_TOOLTIP =
    I18n.t('emma.download.complete.tooltip').freeze

  # Artifact download progress indicator element CSS class.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_CLASS = 'progress'

  # Artifact download progress indicator tooltip.
  #
  # @type [String]
  #
  DOWNLOAD_PROGRESS_TOOLTIP =
    I18n.t('emma.download.progress.tooltip').freeze

  # Artifact download progress indicator relative asset path.
  #
  # @type [String]
  #
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
  DOWNLOAD_BUTTON_LABEL =
    I18n.t('emma.download.button.label').freeze

  # Generic reference to format type for label construction.
  #
  # @type [String]
  #
  THIS_FORMAT = I18n.t('emma.placeholder.format').freeze

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
  # @param [Bs::Api::Record]            item
  # @param [Bs::Record::Format, String] format
  # @param [String, nil]                label
  # @param [Hash]                       opt     Passed to #item_link.
  #
  # @option opt [String] :label
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def artifact_link(item, format, label: nil, **opt)
    periodical = item.is_a?(Bs::Message::PeriodicalSubscription)
    rec_fmt    = (format if format.is_a?(Bs::Record::Format))
    format     = (rec_fmt&.identifier || format)&.to_s
    format   ||= periodical ? PeriodicalFormatType.default : FormatType.default
    label ||=
      begin
        scope   = periodical ? 'periodical_format' : 'book_format'
        default = rec_fmt&.label || item.label
        I18n.t("emma.#{scope}.#{fmt}", default: default)
      end
    opt = append_css_classes(opt, 'link')
    opt[:label] = label
    opt[:path]  = download_path(bookshareId: item.identifier, fmt: format)

    # Set up the tooltip to be shown before the item has been requested.
    opt[:tooltip] =
      I18n.t(
        'emma.download.link.tooltip',
        fmt:     format_label(label),
        default: DOWNLOAD_TOOLTIP
      )
    if has_class?(opt, 'disabled')
      sign_in = 'SIGN-IN REQUIRED' # TODO: I18n
      opt[:tooltip].sub!(/\.?$/, " (#{sign_in})")
    end

    # Set up the tooltip to be shown after the item is actually available for
    # download.
    opt[:'data-turbolinks'] = false
    opt[:'data-complete_tooltip'] =
      I18n.t(
        'emma.download.link.complete.tooltip',
        button:  DOWNLOAD_BUTTON_LABEL,
        default: DOWNLOAD_COMPLETE_TOOLTIP
      )

    # Emit the link and hidden auxiliary elements.
    content_tag(:div, class: 'artifact') do
      item_link(item, **opt) +
        download_progress(class: 'hidden') +
        download_button(class: 'hidden', fmt: label) +
        download_failure(class: 'hidden')
    end
  end

  # Create links to download each artifact of the given item.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #artifact_link except for:
  #
  # @option opt [String] :fmt         One of `FormatType#values`
  # @option opt [String] :separator   Default: #DEFAULT_ELEMENT_SEPARATOR.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_links(item, **opt)
    opt, html_opt = partition_options(opt, :fmt, :separator)
    format_id = opt[:fmt]
    separator = opt[:separator] || DEFAULT_ELEMENT_SEPARATOR
    permitted = can?(:download, Artifact)
    append_css_classes!(html_opt, 'disabled') unless permitted
    formats = item&.formats || []
    formats = formats.select { |fmt| fmt.formatId == format_id } if format_id
    links =
      formats.map { |fmt| artifact_link(item, fmt, html_opt) }.compact.sort
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
    opt[:title] ||= DOWNLOAD_PROGRESS_TOOLTIP
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
    make_link(label, '#', opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Fields from Bs::Record::ArtifactMetadata.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  ARTIFACT_SHOW_FIELDS = {
    Format:                   :fmt,
    BrailleType:              :brailleType,
    BrailleCode:              :brailleCode,
    BrailleGrade:             :brailleGrade,
    BrailleMusicScoreLayout:  :brailleMusicScoreLayout,
    Duration:                 :duration,
    NumberOfVolumes:          :numberOfVolumes,
    DateAdded:                :dateAdded,
    Narrator:                 :narrator,
    Transcriber:              :transcriber,
    Producer:                 :producer,
    Supplier:                 :supplier,
    ExternalIdentifierCode:   :externalIdentifierCode,
    GlobalBookServiceId:      :globalBookServiceId,
    FundingSource:            :fundingSource,
  }.freeze

  # Render an item metadata listing.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def artifact_details(item, **opt)
    item_details(item, :artifact, ARTIFACT_SHOW_FIELDS.merge(opt))
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Fields from Bs::Record::ArtifactMetadata.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  ARTIFACT_INDEX_FIELDS = {
    Format:    :fmt,
    DateAdded: :dateAdded,
  }.freeze

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def artifact_list_entry(item, **opt)
    item_list_entry(item, :artifact, ARTIFACT_INDEX_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
