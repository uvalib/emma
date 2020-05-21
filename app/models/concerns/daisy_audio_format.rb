# app/models/concerns/daisy_audio_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A DAISY AUDIO file object.
#
# @see DaisyFormat
#
module DaisyAudioFormat

  include FileFormat
  include OcfFormat
  include DaisyFormat

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

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  # This method overrides:
  # @see DaisyFormat#configuration
  #
  def configuration
    DAISY_AUDIO_FORMAT
  end

  # parser
  #
  # @return [DaisyAudioParser]
  #
  # This method overrides:
  # @see DaisyFormat#parser
  #
  def parser
    @parser ||= DaisyAudioParser.new(file_handle)
  end

end

__loading_end(__FILE__)
