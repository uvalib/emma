# app/models/concerns/daisy_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A DAISY file object.
#
# @see DaisyAudioFormat
# @see OcfFormat
#
module DaisyFormat

  include OcfFormat

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
  FILE_TYPE = :daisy

  # MIME type(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = [
    'application/x-daisy',            # NOTE: fake MIME type
    # 'application/x-dtbook-xml',     # TODO: DaisyFormat MIME type(s)?
  ].freeze

  # File extension(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = %w(
    daisy
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
  # @see OcfFormat#parser
  #
  def parser
    @parser ||= DaisyParser.new(local_path)
  end

end

__loading_end(__FILE__)
