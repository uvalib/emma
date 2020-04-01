# app/models/concerns/file_attributes.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common house-keeping definitions for file objects.
#
# Subclasses of FileObject (which includes this module) are required to have
# the following constants defined:
#
#   :FILE_TYPE        Symbol
#   :FILE_EXTENSIONS  Array<String>
#   :MIME_TYPES       Array<String>
#
module FileAttributes

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  EXT_SEPARATOR = '.'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Source repository of the file.
  #
  # @return [String, nil]             One of EmmaRepository#values.
  #
  attr_reader :repository

  # Identifier for the repository entry to which the file belongs.
  #
  # @return [String, nil]
  #
  attr_reader :repository_id

  # Format type of the file.
  #
  # @return [Symbol, nil]             One of FileFormat#TYPES.
  #
  attr_reader :fmt

  # Filename extension.
  #
  # @return [String, nil]
  #
  attr_reader :ext

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Full name of the file.
  #
  # @return [String, nil]
  #
  attr_reader :filename

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  # The URL or file directory path used initially to specify the file object.
  #
  # @return [String]
  #
  attr_reader :path
=end

  # Access to a local copy of the file object.
  #
  # @return [FileHandle, nil]
  #
  attr_reader :file_handle

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # set_file_attributes
  #
  # @param [FileProperties, Hash] src
  #
  # @return [void]
  #
  def set_file_attributes(src)
    src = FileProperties.new(src) unless src.is_a?(FileProperties)
    @repository    = src.repository
    @repository_id = src.repository_id
    @fmt           = src.fmt
    @ext           = src.ext
    @filename      = src.filename
  end

  # get_file_attributes
  #
  # @return [FileProperties]
  #
  # == Implementation Notes
  # The instance variables are used here rather than the attributes to avoid
  # prematurely producing completed FileProperties instance by triggering
  # method override of :filename.
  #
  def get_file_attributes
    FileProperties[
      @repository,
      @repository_id,
      @fmt,
      @ext,
      @filename
    ]
  end

end

__loading_end(__FILE__)
