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

  include ResourceHelper
  include PaginationHelper

  # Default link tooltip.
  #
  # @type [String]
  #
  ARTIFACT_SHOW_TOOLTIP =
    I18n.t('emma.artifact.show.tooltip').freeze

  # Default completed link tooltip.
  #
  # @type [String]
  #
  ARTIFACT_COMPLETE_TOOLTIP =
    I18n.t('emma.artifact.show.complete.tooltip').freeze

  # Artifact download progress indicator element CSS class.
  #
  # @type [String]
  #
  ARTIFACT_PROGRESS_CLASS = 'progress'

  # Artifact download progress indicator tooltip.
  #
  # @type [String]
  #
  ARTIFACT_PROGRESS_TOOLTIP =
    I18n.t('emma.artifact.show.progress.tooltip').freeze

  # Artifact download progress indicator relative asset path.
  #
  # @type [String]
  #
  ARTIFACT_PROGRESS_ASSET =
    I18n.t(
      'emma.artifact.show.progress.image.asset',
      #default: ImageHelper::PLACEHOLDER_ASSET
    ).freeze

  # Artifact download progress indicator alt text.
  #
  # @type [String]
  #
  ARTIFACT_PROGRESS_ALT_TEXT =
    I18n.t('emma.artifact.show.progress.image.alt').freeze

  # Artifact download failure message element CSS class.
  #
  # @type [String]
  #
  ARTIFACT_FAILURE_CLASS = 'failure'

  # Artifact download button element CSS class.
  #
  # @type [String]
  #
  ARTIFACT_BUTTON_CLASS = 'button'

  # Artifact download button tooltip.
  #
  # @type [String]
  #
  ARTIFACT_BUTTON_LABEL =
    I18n.t('emma.artifact.show.button.label').freeze

  # Artifact download button tooltip.
  #
  # @type [String]
  #
  ARTIFACT_BUTTON_TOOLTIP =
    I18n.t('emma.artifact.show.button.tooltip').freeze

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
  # @return [Array<???>]
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
  # @param [Object]                   item
  # @param [Api::Format, String, nil] format
  # @param [Hash, nil]                opt     Passed to #item_link except for:
  #
  # @option opt [Api::Format, String] :fmt    One of `Api::FormatType.values`
  # @option opt [Symbol, String]      :label
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def artifact_link(item, format = nil, **opt)
    opt, local = extract_local_options(opt, :fmt, :label)
    fmt   = local[:fmt]
    label = local[:label]
    if format.is_a?(Api::Format)
      fmt   ||= format.identifier
      label ||= I18n.t("emma.format.#{fmt}", default: nil) || format.label
    else
      fmt   ||= Api::FormatType.new.default
      label ||= I18n.t("emma.format.#{fmt}", default: nil) || item.label
    end
    path = artifact_path(id: item.identifier, fmt: fmt)
    opt[:class] = css_classes(opt[:class], 'link')
    opt[:tooltip] =
      I18n.t(
        'emma.artifact.show.link.tooltip',
        fmt:     format_label(label),
        default: ARTIFACT_SHOW_TOOLTIP
      )
    opt[:'data-complete_tooltip'] =
      I18n.t(
        'emma.artifact.show.link.complete.tooltip',
        button:  I18n.t('emma.artifact.show.button.label'),
        default: ARTIFACT_COMPLETE_TOOLTIP
      )
    opt[:'data-turbolinks'] = false
    content_tag(:div, class: 'artifact') do
      item_link(item, label, path, **opt) +
        download_progress(class: 'hidden') +
        download_button(class: 'hidden', fmt: label) +
        download_failure(class: 'hidden')
    end
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
  def format_label(fmt, quote = '"')
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
  # @param [Hash, nil]   opt          Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_progress(image = nil, **opt)
    opt = prepend_css_classes(opt, ARTIFACT_PROGRESS_CLASS)
    opt[:title] ||= ARTIFACT_PROGRESS_TOOLTIP
    opt[:alt]   ||= ARTIFACT_PROGRESS_ALT_TEXT
    opt[:role]  ||= 'button'
    image       ||= asset_path(ARTIFACT_PROGRESS_ASSET)
    image_tag(image, opt)
  end

  # An element to indicate failure.
  #
  # @param [Hash, nil] opt            Passed to #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see appendFailureMessage() in app/assets/javascripts/feature/download.js
  #
  def download_failure(**opt)
    opt = prepend_css_classes(opt, ARTIFACT_FAILURE_CLASS)
    content_tag(:span, '', **opt)
  end

  # An element for direct download of an artifact.
  #
  # @param [String, nil] label
  # @param [Hash, nil]   opt          Passed to #link_to except for:
  #
  # @option opt [String] :label
  # @option opt [String] :fmt         Format label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_button(label = nil, **opt)
    opt   = prepend_css_classes(opt, ARTIFACT_BUTTON_CLASS)
    label = opt.delete(:label) || label || ARTIFACT_BUTTON_LABEL
    fmt   = format_label(opt.delete(:fmt))
    opt[:title] ||= I18n.t('emma.artifact.show.button.tooltip', fmt: fmt)
    opt[:role]  ||= 'button'
    link_to(label, '#', **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fields from Api::ArtifactMetadata.
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

  # artifact_field_values
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         opt
  #
  # @return [Hash{Symbol=>Object}]
  #
  def artifact_field_values(item, **opt)
    field_values(item, ARTIFACT_SHOW_FIELDS.merge(opt))
  end

end

__loading_end(__FILE__)
