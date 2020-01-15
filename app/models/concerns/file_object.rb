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

  include FileAttributes
  include DebugHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [String]               path
  # @param [FileProperties, Hash] opt
  #
  def initialize(path, **opt)
    set_file_attributes(opt)
    @path = path
    @local_path = nil
  end

  # ===========================================================================
  # :section: FileAttributes overrides
  # ===========================================================================

  public

  # ext
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see FileAttributes#ext
  #
  def ext
    @ext ||= self.class.file_extension
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  module ClassMethods

    include FileNameHelper

    # Based on the provided data, generate a file name of the form:
    #
    #   "repo-rootname-fmt.ext"
    #
    # @overload make_file_name(src)
    #   @param [FileProperties, Hash] src
    #   @return [String]
    #
    # @overload make_file_name(src, opt = nil)
    #   @param [String]               src
    #   @param [FileProperties, Hash] opt
    #   @return [String]
    #
    # @see FileNameHelper#extract_file_properties
    #
    def make_file_name(src, opt = nil)
      __debug_args(binding)
      src, opt = [nil, src] if src.is_a?(Hash)
      opt = FileProperties.new(opt)
      opt[:repository]   ||= 'info'
      opt[:repositoryId] ||= '%06d' % rand(1_000_000)
      opt[:fmt]          ||= exemplar.fmt
      opt[:ext]          ||= exemplar.ext
      extract_file_properties(src, opt)[:filename]
    end

    # file_extension
    #
    # @return [String]
    # @return [nil]
    #
    # @see FileNameHelper#FF_EXTS
    #
    def file_extension
      safe_const_get(:PREFERRED_FILE_EXTENSION) || file_extensions.first
    end

    # File extensions defined for the subclass.
    #
    # @return [Array<String>]
    #
    # @see FileNameHelper#FF_EXTS
    #
    def file_extensions
      Array.wrap(safe_const_get(:FILE_EXTENSIONS))
        .map { |s| s.to_s.strip.downcase.presence }
        .compact
    end

    # MIME types defined for the subclass.
    #
    # @return [Array<String>]
    #
    # @see FileNameHelper#FF_MIMES
    #
    def mime_types
      Array.wrap(safe_const_get(:MIME_TYPES))
        .map { |s| s.to_s.strip.downcase.presence }
        .compact
    end

    # An instance of the current subclass.
    #
    # @return [FileObject]
    #
    def exemplar
      @exemplar ||= new(nil)
    end

    # To be run once per type...
    #
    # @return [void]
    #
    def register_mime_types
      types = mime_types
      exts  = file_extensions.map!(&:to_sym)
      type  = types.shift
      ext   = exts.shift
      __debug_args(binding) { { type: type, ext: ext } }
      return unless type && ext
      Mime::Type.register(type, ext, types, exts) # TODO: needed?
      Marcel::MimeType.extend(type, extensions: file_extensions)
    end

  end

  extend ClassMethods

end

__loading_end(__FILE__)
