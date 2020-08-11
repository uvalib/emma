# lib/ext/shrine/lib/shrine/uploaded_file.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Shrine gem.

__loading_begin(__FILE__)

require 'shrine/uploaded_file'

class Shrine

  module UploadedFileExt

    include FileNaming

    # Non-functional hints for RubyMine.
    # :nocov:
    include Shrine::UploadedFile::InstanceMethods unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Bibliographic metadata and remediation information.
    #
    # @raise [UploadConcern::SubmitError]   @see #extract_file_metadata
    #
    # @return [Hash{Symbol=>*}]
    #
    def emma_metadata
      @emma_metadata ||= extract_file_metadata
    end

    # Parse the uploaded file to extract bibliographic metadata and remediation
    # information.
    #
    # @raise [UploadConcern::SubmitError]   If metadata was malformed.
    #
    # @return [Hash{Symbol=>*}]
    #
    #--
    # noinspection RubyUnusedLocalVariable
    #++
    def extract_file_metadata
      mime = fmt = fmt_class = fmt_instance = fmt_parser = fmt_metadata = nil
      ext  = extension
      mime = ext_to_mime(ext)  || mime_type
      fmt  = mime_to_fmt(mime) || ext_to_fmt(ext)
      if fmt
        # Any failure will be addressed in the 'rescue' section.
        # noinspection RubyNilAnalysis
        FileUploader.with_file(io) do |handle|
          fmt_class    = FileNaming.format_class_instance(fmt, handle)
          fmt_instance = fmt_class.new(handle)
          fmt_parser   = fmt_instance.parser
          fmt_metadata = fmt_parser.common_metadata rescue {}
          fmt_metadata[:dc_format] = FileFormat.metadata_fmt(fmt_instance.fmt)
        end
      elsif FileNaming::STRICT_FORMATS
        fmt = fmt_class = fmt_instance = fmt_parser = fmt_metadata = ''
        raise
      else
        {}
      end
      metadata.merge!('mime_type' => mime)
      reject_blanks(fmt_metadata)
    rescue => error
      Log.debug { "#{__method__}: #{error.class}: #{error.message}" }
      if error.message.blank?
        msg =
          if fmt.nil? || fmt_class.nil?
            "#{mime.inspect} is not a recognized file type"
          elsif fmt_instance.nil?
            "Could not create #{fmt.inspect} analyzer"
          elsif fmt_parser.nil?
            "Could not create #{fmt.inspect} parser"
          elsif fmt.present?
            "Could not extract #{fmt.inspect} metadata"
          end
        error = UploadConcern::SubmitError.new(msg)
      end
      raise error
    end

  end

  module UploadedFileDebug

    # Non-functional hints for RubyMine.
    # :nocov:
    include Shrine::UploadedFileExt unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # =========================================================================
    # :section: Shrine::UploadedFile overrides
    # =========================================================================

    public

    # initialize
    #
    # @param [Hash] data
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#initialize
    #
    def initialize(data)
      __debug_upload('NEW') { data.is_a?(Hash) ? data : { data: data } }
      super
    end

    # open
    #
    # @param [Hash] options
    #
    # @return [IO]
    # @return [*]                   Return from block if block given.
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#open
    #
    def open(**options)
      __debug_upload(__method__) { options }
      # noinspection RubyYardReturnMatch
      super
    end

    # download
    #
    # @param [Hash] options
    #
    # @return [Tempfile]
    # @return [*]                   Return from block if block given.
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#download
    #
    def download(**options)
      __debug_upload(__method__) { options }
      super
    end

    # stream
    #
    # @param [String, IO, StringIO] destination
    # @param [Hash]                 options
    #
    # @return [Tempfile]
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#stream
    #
    def stream(destination, **options)
      __debug_upload(__method__) do
        { destination: destination, options: options }
      end
      # noinspection RubyYardReturnMatch
      super
    end

    # read
    #
    # @param [Array] args           Passed to IO#read.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#read
    #
    def read(*args)
      __debug_upload(__method__, *args)
      super
    end

    # rewind
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#rewind
    #
    def rewind
      __debug_upload(__method__)
      super
    end

    # close
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#close
    #
    def close
      __debug_upload(__method__)
      super
    end

    # replace
    #
    # @param [IO, StringIO] io
    # @param [Hash]         options
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#replace
    #
    def replace(io, **options)
      __debug_upload(__method__) { { io: io, options: options } }
      super
    end

    # delete
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#delete
    #
    def delete
      __debug_upload(__method__)
      super
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # extract_file_metadata
    #
    # This method overrides:
    # @see Shrine::UploadedFileExt#extract_file_metadata
    #
    def extract_file_metadata
      __debug_upload(__method__)
      super
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    module DebugMethods

      include Emma::Debug

      # Debug method for this class.
      #
      # @param [Array] args
      # @param [Hash]  opt
      # @param [Proc]  block            Passed to #__debug_items.
      #
      # @return [void]
      #
      def __debug_upload(*args, **opt, &block)
        meth = args.shift
        meth = meth.to_s.upcase if meth.is_a?(Symbol)
        opt[:leader] = ':::SHRINE::: UploadedFile'
        opt[:separator] ||= ' | '
        __debug_items(meth, *args, opt, &block)
      end

    end

    include DebugMethods
    extend  DebugMethods

  end if SHRINE_DEBUG

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Shrine::UploadedFile => Shrine::UploadedFileExt
override Shrine::UploadedFile => Shrine::UploadedFileDebug if SHRINE_DEBUG

__loading_end(__FILE__)
