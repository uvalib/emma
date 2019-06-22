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
  ARTIFACT_SHOW_TOOLTIP = I18n.t('emma.artifact.show.tooltip').freeze

  # Default number of results per page if none was specified.
  #
  # @type [Integer]
  #
  DEFAULT_ARTIFACT_PAGE_SIZE = DEFAULT_PAGE_SIZE

  # Options consumed by #artifact_link.
  #
  # @type [Array<Symbol>]
  #
  ARTIFACT_LINK_OPTIONS = %i[fmt label].freeze

  # ===========================================================================
  # :section: PaginationHelper overrides
  # ===========================================================================

  public

  # Default of results per page.
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see PaginationHelper#default_page_size
  #
  def default_page_size
    DEFAULT_ARTIFACT_PAGE_SIZE
  end

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

  # Create a link to download the given item.
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
    opt, local = extract_local_options(opt, ARTIFACT_LINK_OPTIONS)
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
    opt[:tooltip] = ARTIFACT_SHOW_TOOLTIP
    opt[:'data-turbolinks'] = false
    item_link(item, label, path, **opt)
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
