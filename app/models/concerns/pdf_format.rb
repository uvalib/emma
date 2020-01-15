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

  # MIME type(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = %w(
    application/pdf
  ).freeze

  # File extension(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = %w(
    pdf
  ).freeze

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = {
    Title:        :Title,
    Author:       :Author,
    Keywords:     :Keywords,
    Creator:      :Creator,
    CreationDate: :CreationDate,
    ModifiedDate: :ModDate,
    Subject:      :Subject,
    PdfProducer:  :Producer,
    PdfVersion:   :pdf_version,
    PageCount:    :page_count,
  }.freeze

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

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
