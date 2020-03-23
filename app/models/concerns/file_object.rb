# app/models/concerns/file_object.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for file objects.
#
# @see FileAttributes
#
class FileObject

  include Emma::Debug
  include FileAttributes
  include FileNaming

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [String, StringIO, IO] handle
  # @param [FileProperties, Hash] opt
  #
  def initialize(handle, **opt)
    set_file_attributes(opt)
    case handle
      when StringIO then @file_handle = handle
      when IO       then @file_handle = handle; @filename = handle.path
      else               @filename    = handle
    end
    @fmt ||= self.class.fmt
    @ext ||= self.class.file_extension
  end

  # ===========================================================================
  # :section: FileAttributes overrides
  # ===========================================================================

  public

  # file_handle
  #
  # @return [File, StringIO, nil]
  #
  # This method overrides:
  # @see FileAttributes#file_handle
  #
  def file_handle
    @file_handle ||= (File.open(filename) if filename.present?)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  module ClassMethods

    include FileNaming

    # File format defined for the subclass.
    #
    # @return [Symbol]
    #
    def fmt
      const_get(:FILE_TYPE)
    end

    # file_extension
    #
    # @return [String]
    # @return [nil]
    #
    def file_extension
      safe_const_get(:PREFERRED_FILE_EXTENSION) || file_extensions.first
    end

    # File extensions defined for the subclass.
    #
    # @return [Array<String>]
    #
    def file_extensions
      safe_const_get(:FILE_EXTENSIONS) || []
    end

    # MIME types defined for the subclass.
    #
    # @return [Array<String>]
    #
    def mime_types
      safe_const_get(:MIME_TYPES) || []
    end

    # To be run once per type...
    #
    # @return [void]
    #
    def register_mime_types
      types = mime_types.map(&:to_s)
      exts  = file_extensions.map(&:to_sym)
      type  = types.shift
      ext   = exts.shift
      __debug_args(binding) do
        { type: type, ext: ext, types: types, exts: exts }
      end
      return unless type && ext
      Mime::Type.register(type, ext, types, exts) # TODO: needed?
      Marcel::MimeType.extend(type, extensions: file_extensions.map(&:to_s))
    end

  end

  extend ClassMethods

end

__loading_end(__FILE__)
