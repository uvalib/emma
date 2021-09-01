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
  PDF_FORMAT = FileFormat.configuration(FILE_TYPE).deep_freeze

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
  def format_date(value)
    super(scrub_date(value))
  end

  # format_date_time
  #
  # @param [String, Date, DateTime] value
  #
  # @return [String]
  #
  def format_date_time(value)
    super(scrub_date(value))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Eliminate PDF date string content that would confuse Date#parse, including
  # converting ISO/IEC 8824 (ASN.1) formats.
  #
  # @param [String, *] value
  #
  # @return [String, *]
  #
  # @see http://www.verypdf.com/pdfinfoeditor/pdf-date-format.htm
  #
  def scrub_date(value)
    return value unless value.is_a?(String)

    # Strip optional date tag.  If the remainder is just four digits, pass it
    # back as a year value in a form that Date#parse will accept.  If the
    # remainder doesn't have have at least five digits then assume this is not
    # an ASN.1 style date and that, hopefully, Date#parse can deal with it.
    value = value.strip.sub(/^D:/i, '')
    return "#{$1}/01" if value.match(/^(\d{4})$/)
    return value      unless value.match(/^\d{5}/)

    # Strip the optional timezone from the end so that *tz* is either *nil*,
    # 'Z', "-hh:mm" or "+hh:mm".  (The single quotes are supposed to be
    # required, but this will attempt to handle variations that aren't too
    # off-the-wall.)
    tz = nil
    value.sub!(/([Z+-])((\d{2})[':]?((\d{2})[':]?)?)?$/i) do
      hm = '+-'.include?($1) && [$3, $5].compact_blank.join(':').presence
      tz = hm ? "#{$1}#{hm}" : 'Z'
      nil
    end

    # Get optional date and time parts.  Because Date#parse won't accept
    # something like "2021-12" but will correctly interpret "2021/12" as
    # "December 2021", '/' is used as the date separator.
    dt = []
    # noinspection RubyResolve
    value.sub!(/(\d{4})((\d{2})((\d{2})((\d{2})((\d{2})(\d{2})?)?)?)?)?/) do
      dt << [$1, $3, $5 ].compact_blank.join('/') # Date parts
      dt << [$7, $9, $10].compact_blank.join(':') # Time parts
      dt << tz                                    # Time zone
    end
    dt.compact_blank!.join(' ')
  end

end

__loading_end(__FILE__)
