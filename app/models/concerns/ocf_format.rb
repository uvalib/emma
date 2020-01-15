# app/models/concerns/ocf_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An OCF-based file object.
#
# @see DaisyFormat
# @see EpubFormat
# @see FileFormat
#
module OcfFormat

  include FileFormat

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = {

    CoverImage:           :cover_image,

    # Dublin Core

    Title:                :title,
    Author:               :author,                # Not Dublin Core
    Editor:               :editor,                # Not Dublin Core
    Creator:              :creator,
    Contributor:          :contributor,
    Language:             :language,
    Date:                 :date,
    Publisher:            :publisher,
    PublicationDate:      :publication_date,      # <date event="publication">
    Subject:              :subject,
    Type:                 :type,
    Rights:               :rights,
    Format:               :formats,
    Source:               :source,
    Coverage:             :coverage,
    Relation:             :relation,
    Description:          :description,
    Identifier:           :identifier,

    # Schema.org

    AccessibilityFeature: :accessibility_feature,
    AccessibilityHazard:  :accessibility_hazard,
    AccessibilityControl: :accessibility_control,
    AccessMode:           :access_mode,
    AccessModeSufficient: :access_mode_sufficient,
    AccessibilitySummary: :accessibility_summary,

    # DTBook x-metadata

    Synopsis:             :synopsis,              # not in DTBook
    RunningTime:          :total_time,            # 0 for type == 'textNCX'
    AudioFormat:          :audio_format,
    Narrator:             :narrator,
    MultimediaType:       :multimedia_type,
    MultimediaContent:    :multimedia_content,
    SourceTitle:          :source_title,
    SourceRights:         :source_rights,
    SourceEdition:        :source_edition,
    SourceDate:           :source_date,
    SourcePublisher:      :source_publisher,
    Producer:             :producer,
    ProductionDate:       :produced_date,
    Revision:             :revision,
    RevisionDate:         :revision_date,
    RevisionDescription:  :revision_description,
    ModifiedDate:         :modified,              # not in DTBook

    # From *.ncx file

    Uid:                  :uid,
    Depth:                :depth,
    Generator:            :generator,
    Pages:                :total_page_count,      # 0 => no navigable pages
    MaxPageNumber:        :max_page_number,       # 0 => no navigable pages

  }.freeze

end

__loading_end(__FILE__)
