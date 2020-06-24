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

  # Access to a local copy of the file object.
  #
  # @return [FileHandle, nil]
  #
  attr_reader :file_handle

end

__loading_end(__FILE__)
