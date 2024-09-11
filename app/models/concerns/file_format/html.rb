# app/models/concerns/file_format/html.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HTML file format support.
#
module FileFormat::Html

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
  FILE_TYPE = :html

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  HTML_FORMAT = FileFormat.configuration(FILE_TYPE)

  # MIME type(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = HTML_FORMAT[:mimes]

  # File extension(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = HTML_FORMAT[:exts]

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = HTML_FORMAT[:fields]

  # A mapping of format field to the equivalent Search::Record::MetadataRecord
  # field.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # @see FileFormat#mapped_metadata_fields
  #
  FIELD_MAP = HTML_FORMAT[:map]

  # Indicate whether files of the given type should be processed to extract
  # bibliographic metadata when being uploaded.
  #
  # @type [Boolean]
  #
  UPLOAD_PARSE = HTML_FORMAT.dig(:upload, :parse) || false

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  def configuration
    HTML_FORMAT
  end

  # parser
  #
  # @return [FileParser::Html]
  #
  def parser
    @parser ||= FileParser::Html.new(file_handle)
  end

end

__loading_end(__FILE__)
