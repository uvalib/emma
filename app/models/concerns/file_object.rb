# app/models/concerns/file_object.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for file objects.
#
# @see FileNaming
# @see FileHandle
#
class FileObject

  include Emma::Debug
  include FileNaming

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [String, FileHandle, IO, StringIO, Tempfile, IO::Like] handle
  # @param [Symbol, String, nil] fmt  Override `self.class.fmt`.
  # @param [String, nil]         ext  Override `self.class.file_extension`.
  #
  # == Variations
  #
  # @overload initialize(path, fmt: nil, ext: nil)
  #   @param [String]              path
  #   @param [Symbol, String, nil] fmt
  #   @param [String, nil]         ext
  #
  # @overload initialize(handle, fmt: nil, ext: nil)
  #   @param [FileHandle, IO, StringIO, Tempfile, IO::Like] handle
  #   @param [Symbol, String, nil] fmt
  #   @param [String, nil]         ext
  #
  def initialize(handle, fmt: nil, ext: nil)
    @fmt         = fmt || self.class.fmt
    @ext         = ext || self.class.file_extension
    @file_handle = handle.is_a?(FileHandle) ? handle : FileHandle.new(handle)
    @filename    = (@file_handle.path if @file_handle.respond_to?(:path))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Format type of the file.
  #
  # @return [Symbol]                  One of FileFormat#TYPES.
  #
  attr_reader :fmt

  # Filename extension.
  #
  # @return [String, nil]
  #
  attr_reader :ext

  # filename
  #
  # @return [String, nil]
  #
  def filename
    @filename ||= (@file_handle.path if @file_handle.respond_to?(:path))
  end

  # file_handle
  #
  # @return [FileHandle, nil]
  #
  def file_handle
    @file_handle ||= (FileHandle.new(filename) if filename.present?)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  module ClassMethods

    include Emma::Debug
    include FileNaming

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # File format defined for the subclass.
    #
    # @raise [NameError]              If the subclass does not define FILE_TYPE
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

    if not DEBUG_MIME_TYPE

      def __debug_mime(*); end

    else

      include Emma::Debug::OutputMethods

      # __debug_mime
      #
      # @param [Binding] bind         Passed to #__debug_items.
      # @param [Proc]    block        Passed to #__debug_items.
      #
      # @return [nil]
      #
      def __debug_mime(bind, &block)
        __debug_items(bind, &block)
      end

    end

  end

  extend ClassMethods

end

__loading_end(__FILE__)
