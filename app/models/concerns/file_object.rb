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
  #--
  # === Variations
  #++
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
  #--
  # noinspection RubyMismatchedVariableType, RailsParamDefResolve
  #++
  def initialize(handle, fmt: nil, ext: nil)
    @fmt         = fmt || self.class.fmt
    @ext         = ext || self.class.file_extension
    @file_handle = handle.is_a?(FileHandle) ? handle : FileHandle.new(handle)
    @filename    = @file_handle.try(:path)
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
    # noinspection RailsParamDefResolve
    @filename ||= @file_handle.try(:path)
  end

  # file_handle
  #
  # @return [FileHandle, nil]
  #
  def file_handle
    # noinspection RubyMismatchedArgumentType
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

    # To be run once per type to update Marcel::MimeType.
    #
    # @return [void]
    #
    def register_mime_types
      types = mime_types.map(&:to_s)
      type  = types.shift or return
      __debug_mime(binding) do
        exts = file_extensions.map(&:to_sym)
        ext  = exts.shift
        { type: type, ext: ext, types: types, exts: exts }
      end
      Marcel::MimeType.extend(type, extensions: file_extensions)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    if not DEBUG_MIME_TYPE

      def __debug_mime(...); end

    else

      include Emma::Debug::OutputMethods

      # __debug_mime
      #
      # @param [Binding] bind         Passed to #__debug_items.
      # @param [Proc]    blk          Passed to #__debug_items.
      #
      # @return [nil]
      #
      def __debug_mime(bind, &blk)
        __debug_items(bind, &blk)
      end

    end

  end

  extend ClassMethods

end

# =============================================================================
# Pre-load format-specific classes for easier TRACE_LOADING.
# =============================================================================

require_subclasses(__FILE__)

__loading_end(__FILE__)
