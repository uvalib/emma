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

  include DaisyFormat

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
  FILE_TYPE = :daisyAudio

  # MIME type(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = [
    'application/x-daisy',            # NOTE: fake MIME type
    # 'application/x-dtbook-xml',     # TODO: DaisyAudioFormat MIME type(s)?
  ].freeze

  # File extension(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  # TODO: Unsure about "dtbook".
  #
  FILE_EXTENSIONS = %w(
    daisy
    daisyAudio
    dtbook
  ).freeze

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # parser
  #
  # @return [DaisyParser]
  #
  # This method overrides:
  # @see DaisyFormat#parser
  #
  def parser
    @parser ||= DaisyParser.new(local_path)
  end

end

__loading_end(__FILE__)
