# app/models/concerns/pdf_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A PDF file object.
#
# @see FileFormat
#
module PdfFormat

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
  FILE_TYPE = :pdf

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  PDF_FORMAT = format_configuration(FILE_TYPE).deep_freeze

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
  FIELD_MAP = PDF_FORMAT[:map]

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  # This method overrides:
  # @see FileFormat#configuration
  #
  def configuration
    PDF_FORMAT
  end

  # parser
  #
  # @return [PdfParser]
  #
  # This method overrides:
  # @see FileFormat#parser
  #
  def parser
    @parser ||= PdfParser.new(local_path)
  end

  # parser_metadata
  #
  # @return [PdfParser]
  #
  # This method overrides:
  # @see FileFormat#parser_metadata
  #
  def parser_metadata
    parser
  end

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  protected

  # format_date
  #
  # @param [String, Date, DateTime] value
  #
  # @return [String]
  #
  # This method overrides:
  # @see FileFormat#format_date
  #
  def format_date(value)
    super(scrub_date(value))
  end

  # format_date_time
  #
  # @param [String, Date, DateTime] value
  #
  # @return [String]
  #
  # This method overrides:
  # @see FileFormat#format_date_time
  #
  def format_date_time(value)
    super(scrub_date(value))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Eliminate PDF date string content that would confuse Date#parse.
  #
  # @param [String, *] value
  #
  # @return [String, *]
  #
  def scrub_date(value)
    value.is_a?(String) ? value.sub(/Z.*$/, 'Z') : value
  end

end

__loading_end(__FILE__)
