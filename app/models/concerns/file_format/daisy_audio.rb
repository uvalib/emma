# app/models/concerns/file_format/daisy_audio.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# DAISY AUDIO file format support.
#
# @see FileFormat::Daisy
#
module FileFormat::DaisyAudio

  include FileFormat
  include FileFormat::Ocf
  include FileFormat::Daisy

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
  FILE_TYPE = :daisyAudio

  # Configured properties for this file format.
  #
  # @type [Hash{Symbol=>String,Array,Hash}]
  #
  DAISY_AUDIO_FORMAT =
    FileFormat.configuration(DAISY_FORMAT, FILE_TYPE).deep_freeze

  # MIME type(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = DAISY_AUDIO_FORMAT[:mimes]

  # File extension(s) associated with instances of this file format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = DAISY_AUDIO_FORMAT[:exts]

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = DAISY_AUDIO_FORMAT[:fields]

  # A mapping of format field to the equivalent Search::Record::MetadataRecord
  # field.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # @see FileFormat#mapped_metadata_fields
  #
  FIELD_MAP = DAISY_AUDIO_FORMAT[:map]

  # Indicate whether files of the given type should be processed to extract
  # bibliographic metadata when being uploaded.
  #
  # @type [Boolean]
  #
  UPLOAD_PARSE = DAISY_AUDIO_FORMAT.dig(:upload, :parse) || false

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  def configuration
    DAISY_AUDIO_FORMAT
  end

  # parser
  #
  # @return [FileParser::DaisyAudio]
  #
  def parser
    @parser ||= FileParser::DaisyAudio.new(file_handle)
  end

end

__loading_end(__FILE__)
