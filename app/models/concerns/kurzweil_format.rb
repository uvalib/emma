# app/models/concerns/kurzweil_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Kurzweil file object.
#
module KurzweilFormat

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
  FILE_TYPE = :kurzweil

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  KURZWEIL_FORMAT = format_configuration(FILE_TYPE).deep_freeze

  # MIME type(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = KURZWEIL_FORMAT[:mimes]

  # File extension(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = KURZWEIL_FORMAT[:exts]

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = KURZWEIL_FORMAT[:fields]

  # A mapping of format field to the equivalent Search::Record::MetadataRecord
  # field.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  FIELD_MAP = KURZWEIL_FORMAT[:map]

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
    KURZWEIL_FORMAT
  end

  # parser
  #
  # @return [KurzweilParser]
  #
  # This method overrides:
  # @see FileFormat#parser
  #
  def parser
    @parser ||= KurzweilParser.new(local_path)
  end

end

__loading_end(__FILE__)
