# app/models/concerns/epub_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An EPUB file object.
#
# @see OcfFormat
#
module EpubFormat

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
  FILE_TYPE = :epub

  # MIME type(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = %w(
    application/epub+zip
    application/epub-file
  ).freeze

  # File extension(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = %w(
    epub
    epub3
  ).freeze

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # parser
  #
  # @return [EpubParser]
  #
  # This method overrides:
  # @see OcfFormat#parser
  #
  def parser
    @parser ||= EpubParser.new(local_path)
  end

end

__loading_end(__FILE__)
