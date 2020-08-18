# app/models/concerns/file_object.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for file objects.
#
# @see FileAttributes
# @see FileNaming
# @see FileHandle
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
  # @param [String, FileHandle, IO, StringIO, Tempfile, IO::Like] handle
  # @param [Hash]                                                 opt
  #
  # == Variations
  #
  # @overload initialize(path, opt = nil)
  #   @param [String] path
  #   @param [Hash]   opt
  #
  # @overload initialize(handle, opt = nil)
  #   @param [FileHandle, IO, StringIO, Tempfile, IO::Like] handle
  #   @param [Hash]                                         opt
  #
  def initialize(handle, opt = nil)
    opt = opt&.symbolize_keys || {}
    @repository    = opt[:repository]
    @repository_id = opt[:repository_id]
    @fmt           = opt[:fmt] || self.class.fmt
    @ext           = opt[:ext] || self.class.file_extension
    @file_handle   = handle.is_a?(FileHandle) ? handle : FileHandle.new(handle)
    @filename      = (@file_handle.path if @file_handle.respond_to?(:path))
  end

  # ===========================================================================
  # :section: FileAttributes overrides
  # ===========================================================================

  public

  # filename
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see FileAttributes#filename
  #
  def filename
    @filename ||= (@file_handle.path if @file_handle.respond_to?(:path))
  end

  # file_handle
  #
  # @return [FileHandle, nil]
  #
  # This method overrides:
  # @see FileAttributes#file_handle
  #
  def file_handle
    @file_handle ||= (FileHandle.new(filename) if filename.present?)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  module ClassMethods

    include FileNaming

    # Set to show registration of unique MIME types during startup.
    #
    # @type [Boolean]
    #
    MIME_TYPE_DEBUG = true?(ENV['MIME_TYPE_DEBUG'])

    # =========================================================================
    # :section:
    # =========================================================================

    public

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
      __debug_mime(binding) do
        { type: type, ext: ext, types: types, exts: exts }
      end
      return unless type && ext
      Mime::Type.register(type, ext, types, exts) # TODO: needed?
      Marcel::MimeType.extend(type, extensions: file_extensions.map(&:to_s))
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # __debug_mime
    #
    # @param [Binding] bind           Passed to #__debug_args.
    # @param [Proc]    block          Passed to #__debug_args.
    #
    # @return [void]
    #
    def __debug_mime(bind, &block)
      __debug_args(bind, &block)
    end

    unless MIME_TYPE_DEBUG
      def __debug_mime(*); end
    end

  end

  extend ClassMethods

end

__loading_end(__FILE__)
