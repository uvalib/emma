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

  # Default number of results per page if none was specified.
  #
  # @type [Integer]
  #
  DEFAULT_ARTIFACT_PAGE_SIZE = DEFAULT_PAGE_SIZE

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
  # @param [Hash, nil]                opt
  #
  # @option opt [Symbol, String] :label
  # @option opt [String]         :type  One of `Api::FormatType.values`
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def artifact_link(item, format = nil, **opt)
    label = opt[:label]
    if format.is_a?(Api::Format)
      type = format.identifier
      name = format.label
    else
      type = opt[:type] || opt[:format] || Api::FormatType.new.default
      name = item.label
      label ||= format
    end
    label ||= I18n.t("emma.format.#{type}", default: nil) || name
    path = artifact_path(id: item.identifier, type: type)
    opt = opt.except(:label, :type, :format)
    opt[:title] = 'Download this artifact.'
    opt[:'data-turbolinks'] = false
    link_to(label, path, opt)
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
    Format:                   :format,
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
