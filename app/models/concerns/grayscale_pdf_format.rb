# app/models/concerns/grayscale_pdf_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Grayscale PDF file object.
#
# @see PdfFormat
#
module GrayscalePdfFormat

  include FileFormat
  include PdfFormat

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
  FILE_TYPE = :grayscalePdf

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  GRAYSCALE_PDF_FORMAT =
    format_configuration(PDF_FORMAT, FILE_TYPE).deep_freeze

  # MIME type(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = GRAYSCALE_PDF_FORMAT[:mimes]

  # File extension(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = GRAYSCALE_PDF_FORMAT[:exts]

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = GRAYSCALE_PDF_FORMAT[:fields]

  # A mapping of format field to the equivalent Search::Record::MetadataRecord
  # field.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # @see FileFormat#mapped_metadata_fields
  #
  FIELD_MAP = GRAYSCALE_PDF_FORMAT[:map]

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  # This method overrides:
  # @see OcfFormat#configuration
  #
  def configuration
    GRAYSCALE_PDF_FORMAT
  end

  # parser
  #
  # @return [GrayscalePdfParser]
  #
  # This method overrides:
  # @see OcfFormat#parser
  #
  def parser
    @parser ||= GrayscalePdfParser.new(file_handle)
  end

end

__loading_end(__FILE__)