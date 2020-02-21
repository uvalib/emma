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
  # @param [String, StringIO, IO] path
  # @param [FileProperties, Hash] opt
  #
  def initialize(path, **opt)
    set_file_attributes(opt)
    case path
      when StringIO then @local_path = path
      when IO       then @path = path.path; @local_path = path
      else               @path = path
    end
    @fmt ||= self.class.fmt
    @ext ||= self.class.file_extension
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  module ClassMethods

    include FileNaming

  if LOCAL_DOWNLOADS
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
    # @see FileNaming#extract_file_properties
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
  end

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

  if LOCAL_DOWNLOADS
    # An instance of the current subclass.
    #
    # @return [FileObject]
    #
    def exemplar
      @exemplar ||= new(nil)
    end
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
      __debug_args(binding) { { type: type, ext: ext, types: types, exts: exts } }
      return unless type && ext
      Mime::Type.register(type, ext, types, exts) # TODO: needed?
      Marcel::MimeType.extend(type, extensions: file_extensions.map(&:to_s))
    end

  end

  extend ClassMethods

end

__loading_end(__FILE__)
