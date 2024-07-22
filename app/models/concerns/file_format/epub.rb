# app/models/concerns/file_format/epub.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EPUB file format support.
#
# @see FileFormat::Ocf
#
module FileFormat::Epub

  include FileFormat
  include FileFormat::Ocf

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
  FILE_TYPE = :epub

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  EPUB_FORMAT = FileFormat.configuration(*OCF_FORMAT, FILE_TYPE)

  # MIME type(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = EPUB_FORMAT[:mimes]

  # File extension(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = EPUB_FORMAT[:exts]

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = EPUB_FORMAT[:fields]

  # A mapping of format field to the equivalent Search::Record::MetadataRecord
  # field.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # @see FileFormat#mapped_metadata_fields
  #
  FIELD_MAP = EPUB_FORMAT[:map]

  # Indicate whether files of the given type should be processed to extract
  # bibliographic metadata when being uploaded.
  #
  # @type [Boolean]
  #
  UPLOAD_PARSE = EPUB_FORMAT.dig(:upload, :parse) || false

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  def configuration
    EPUB_FORMAT
  end

  # parser
  #
  # @return [FileParser::Epub]
  #
  def parser
    @parser ||= FileParser::Epub.new(file_handle)
  end

end

__loading_end(__FILE__)
