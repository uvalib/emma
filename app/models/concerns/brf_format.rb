# app/models/concerns/brf_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A BRF file object.
#
module BrfFormat

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
  FILE_TYPE = :brf

  # MIME type(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#mime_types
  #
  MIME_TYPES = [
    'application/x-brf',              # NOTE: fake MIME type
  ].freeze

  # File extension(s) associated with instances of this format.
  #
  # @type [Array<String>]
  #
  # @see FileObject#file_extensions
  #
  FILE_EXTENSIONS = %w(
    brf
  ).freeze

  # FORMAT_FIELDS
  #
  # @type [Hash{Symbol=>Proc,Symbol}]
  #
  # @see FileFormat#format_fields
  #
  FORMAT_FIELDS = {
    # TODO: BRF fields?
  }.freeze

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # parser
  #
  # @return [BrfParser]
  #
  # This method overrides:
  # @see FileFormat#parser
  #
  def parser
    @parser ||= BrfParser.new(local_path)
  end

end

__loading_end(__FILE__)
