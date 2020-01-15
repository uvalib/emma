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

  extend ActiveSupport::Concern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  NAME_PART_SEPARATOR = '-'
  FILE_ID_SEPARATOR   = ','
  EXT_SEPARATOR       = '.'

  FILE_ID_CHARS = 'a-zA-Z0-9_.-'

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

  # Repository identifier for the file.  (HathiTrust)
  #
  # @return [String, nil]
  #
  attr_reader :file_id

  # Format type of the file.
  #
  # @return [Symbol, nil]             One of FileFormat#FILE_FORMATS.
  #
  attr_reader :fmt

  # Filename extension.
  #
  # @return [String, nil]
  #
  attr_reader :ext

  # Core portion of the name associated with the file.
  #
  # @return [String, nil]
  #
  # @see #make_rootname
  #
  attr_reader :rootname

  # Full name of the file.
  #
  # @return [String, nil]
  #
  # @see #make_filename
  #
  attr_reader :filename

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL or file directory path used initially to specify the file object.
  #
  # @return [String]
  #
  attr_reader :path

  # File system path to a local copy of the file object.
  #
  # @return [String, nil]
  #
  attr_reader :local_path

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
    @file_id       = src.file_id
    @fmt           = src.fmt
    @ext           = src.ext
    @rootname      = src.rootname
    @filename      = src.filename
  end

  # get_file_attributes
  #
  # @return [FileProperties]
  #
  # == Implementation Notes
  # The instance variables are used here rather than the attributes to avoid
  # prematurely producing completed FileProperties instance by triggering
  # method overrides of :rootname and/or :filename.
  #
  def get_file_attributes
    FileProperties[
      @repository,
      @repository_id,
      @file_id,
      @fmt,
      @ext,
      @rootname,
      @filename
    ]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # sanitize_id
  #
  # @param [String, Symbol] value
  #
  # @return [String]
  #
  def sanitize_id(value)
    value.to_s.tr("^#{FILE_ID_CHARS}", '_')
  end

  # make_rootname
  #
  # @return [String]
  # @return [nil]
  #
  def make_rootname
    parts = [repository_id, file_id].compact.presence
    parts&.map { |v| sanitize_id(v) }&.join(FILE_ID_SEPARATOR)
  end

  # make_filename
  #
  # @return [String]
  # @return [nil]
  #
  def make_filename
    parts = [repository, rootname, fmt].compact.presence
    parts&.join(NAME_PART_SEPARATOR)&.tap { |name|
      (suffix = ext || fmt&.to_s) and (name << EXT_SEPARATOR << suffix)
    }
  end

end

__loading_end(__FILE__)
