# app/models/concerns/tactile_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Tactile file object.
#
module TactileFormat

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
  FILE_TYPE = :tactile

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  TACTILE_FORMAT = format_configuration(FILE_TYPE).deep_freeze

  # MIME type(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = TACTILE_FORMAT[:mimes]

  # File extension(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = TACTILE_FORMAT[:exts]

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = TACTILE_FORMAT[:fields]

  # A mapping of format field to the equivalent Search::Record::MetadataRecord
  # field.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  FIELD_MAP = TACTILE_FORMAT[:map]

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
    TACTILE_FORMAT
  end

  # parser
  #
  # @return [TactileParser]
  #
  # This method overrides:
  # @see FileFormat#parser
  #
  def parser
    @parser ||= TactileParser.new(local_path)
  end

end

__loading_end(__FILE__)
