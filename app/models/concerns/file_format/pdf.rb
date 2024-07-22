# app/models/concerns/file_format/pdf.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# PDF file format support.
#
module FileFormat::Pdf

  include FileFormat

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Type of associated files.
  #
  # @type [Symbol]                    One of FileFormat#TYPES
  #
  # @see FileObject#fmt
  #
  FILE_TYPE = :pdf

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  PDF_FORMAT = FileFormat.configuration(FILE_TYPE)

  # MIME type(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = PDF_FORMAT[:mimes]

  # File extension(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = PDF_FORMAT[:exts]

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = PDF_FORMAT[:fields]

  # A mapping of format field to the equivalent Search::Record::MetadataRecord
  # field.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # @see FileFormat#mapped_metadata_fields
  #
  FIELD_MAP = PDF_FORMAT[:map]

  # Indicate whether files of the given type should be processed to extract
  # bibliographic metadata when being uploaded.
  #
  # @type [Boolean]
  #
  UPLOAD_PARSE = PDF_FORMAT.dig(:upload, :parse) || false

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  def configuration
    PDF_FORMAT
  end

  # parser
  #
  # @return [FileParser::Pdf]
  #
  def parser
    @parser ||= FileParser::Pdf.new(file_handle)
  end

  # parser_metadata
  #
  # @return [FileParser::Pdf]
  #
  def parser_metadata
    parser
  end

end

__loading_end(__FILE__)
