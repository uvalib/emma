# app/models/concerns/word_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Microsoft Word (.docx) file object.
#
# @see FileFormat
#
module WordFormat

  include FileFormat

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Type of associated files.
  #
  # @type [Symbol]                    One of FileFormat#FILE_FORMATS
  #
  # @see FileObject#fmt
  #
  FILE_TYPE = :word

  # MIME type(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # Also (maybe):
  #   application/vnd.ms-word.document.macroEnabled.12
  #   application/vnd.ms-word.template.macroEnabled.12
  #
  # Related:
  #   application/vnd.ms-excel
  #   application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = %w(
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ).freeze

  # File extension(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # Also (maybe):
  #   word
  #   dot
  #   wiz
  #   rtf
  #
  # Related:
  #   xls
  #   xlsx
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = %w(
    docx
    doc
  ).freeze

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = {

    # Dublin Core (except as noted)

    Title:            :title,
    Author:           :author,              # coreProperties
    Creator:          :creator,
    Contributor:      :contributor,
    Language:         :language,
    Date:             %i[date_copyrighted modified date_submitted created],
    Publisher:        :publisher,
    Subject:          :subject,
    Type:             :type,
    Rights:           :rights,
    Format:           :formats,
    Source:           :source,
    Coverage:         :coverage,
    Relation:         :relation,
    Description:      :description,
    Identifier:       :identifier,

    # (Partial) Qualified Dublin Core (except as noted)

    Abstract:         :abstract,
    Contents:         :table_of_contents,
    Audience:         :audience,
    EducationLevel:   :education_level,
    Extent:           :extent,
    Medium:           :medium,
    Spatial:          :spatial,
    Requires:         :requires,
    License:          :license,
    Issued:           :issued,
    IsPartOf:         :is_part_of,
    IsVersionOf:      :is_version_of,
    CreationDate:     :created,
    Accepted:         :date_accepted,
    CopyrightDate:    :date_copyrighted,
    SubmissionDate:   :date_submitted,
    ModifiedDate:     :modified,
    LastModifiedBy:   :last_modified_by,    # coreProperties
    RightsHolder:     :rights_holder,
    Provenance:       :provenance,

    # Core properties (coreProperties)

    # Author:         :author,
    Category:         :category,
    ContentStatus:    :content_status,
    Version:          :version,
    Revision:         :revision,
    # ModifiedDate:   :modified,
    # LastModifiedBy: :last_modified_by,
    Keywords:         :keywords,
    Comments:         :comments,

  }.freeze

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # parser
  #
  # @return [WordParser]
  #
  # This method overrides:
  # @see FileFormat#parser
  #
  def parser
    @parser ||= WordParser.new(local_path)
  end

end

__loading_end(__FILE__)
