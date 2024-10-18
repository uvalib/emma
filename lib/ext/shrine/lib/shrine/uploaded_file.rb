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

    include Emma::Common
    include Emma::Mime

    # Non-functional hints for RubyMine type checking.
    # :nocov:
    unless ONLY_FOR_DOCUMENTATION
      include Shrine::UploadedFile::InstanceMethods
    end
    # :nocov:

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Bibliographic metadata and remediation information.
    #
    # @raise [Record::SubmitError]    @see #extract_file_metadata
    #
    # @return [Hash{Symbol=>any}]
    #
    def emma_metadata
      @emma_metadata ||= extract_file_metadata
    end

    # Parse the uploaded file to extract bibliographic metadata and remediation
    # information.
    #
    # @raise [Record::SubmitError]    If metadata was malformed.
    #
    # @return [Hash{Symbol=>any}]
    #
    def extract_file_metadata
      parse = false
      mime  = fmt = fmt_cls = instance = parser = nil
      data  = {}
      ext   = extension
      mime  = ext_to_mime(ext) || mime_type
      fmt   = (FileNaming.mime_to_fmt[mime]&.first if mime)
      fmt ||= (FileNaming.ext_to_fmt[ext]&.first   if ext)
      if fmt
        daisy   = %i[daisy daisyAudio].include?(fmt)
        fmt_cls = FileNaming.format_class(fmt)          unless daisy
        parse   = fmt_cls.safe_const_get(:UPLOAD_PARSE) if fmt_cls
        if parse || daisy
          FileUploader.with_file(io) do |handle|
            fmt_cls ||= FileNaming.format_class(fmt, handle)
            instance  = fmt_cls&.new(handle)
            parse     = instance.extract_on_upload?      if instance
            parser    = instance.parser                  if parse
            data      = parser.common_metadata rescue {} if parser
          end
        end
        data[:dc_format] = FileFormat.metadata_fmt(instance.fmt) if instance
      elsif FileNaming::STRICT_FORMATS
        raise
      end
      metadata.merge!('mime_type' => mime)
      reject_blanks(data)
    rescue => error
      Log.debug { "#{__method__}: #{error.class}: #{error.message}" }
      if error.message.blank?
        msg =
          if FileNaming::STRICT_FORMATS
            "unknown MIME type #{mime.inspect}, extension #{ext.inspect}"
          elsif fmt.nil? || fmt_cls.nil?
            "#{mime.inspect} is not a recognized file type"
          elsif instance.nil?
            "Could not create #{fmt.inspect} analyzer"
          elsif parse && parser.nil?
            "Could not create #{fmt.inspect} parser"
          else
            "Could not extract #{fmt.inspect} metadata"
          end
        raise Record::SubmitError, "#{__method__}: #{msg}"
      end
      raise error
    end

  end

  if DEBUG_SHRINE

    # Overrides adding extra debugging around method calls.
    #
    module UploadedFileDebug

      include Shrine::ExtensionDebugging

      # Non-functional hints for RubyMine type checking.
      # :nocov:
      unless ONLY_FOR_DOCUMENTATION
        include Shrine::UploadedFileExt
      end
      # :nocov:

      # =======================================================================
      # :section: Shrine::UploadedFile overrides
      # =======================================================================

      public

      # initialize
      #
      # @param [Hash] data
      #
      def initialize(data)
        __ext_debug { data.is_a?(Hash) ? data : { data: data } }
        super
      end

      # open
      #
      # @param [Hash] options
      #
      # @return [IO]
      # @return [any]                 Return from block if block given.
      #
      def open(**options)
        __ext_debug { options }
        # noinspection RubyMismatchedReturnType
        super
      end

      # download
      #
      # @param [Hash] options
      #
      # @return [Tempfile]
      # @return [any]                 Return from block if block given.
      #
      def download(**options)
        __ext_debug { options }
        super
      end

      # stream
      #
      # @param [String, IO, StringIO] destination
      # @param [Hash]                 options
      #
      # @return [IO]
      #
      def stream(destination, **options)
        __ext_debug do
          { destination: destination, options: options, '@io' => @io }
        end
        super
      end

      # read
      #
      # @param [Array] args           Passed to IO#read.
      #
      # @return [String]
      #
      def read(*args)
        __ext_debug(*args)
        super
      end

      # rewind
      #
      # @return [void]
      #
      def rewind
        __ext_debug
        super
      end

      # close
      #
      # @return [void]
      #
      def close
        __ext_debug
        super
      end

      # replace
      #
      # @param [IO, StringIO] io
      # @param [Hash]         options
      #
      # @return [void]
      #
      def replace(io, **options)
        __ext_debug { { io: io, options: options } }
        super
      end

      # delete
      #
      # @return [void]
      #
      def delete
        __ext_debug
        super
      end

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # extract_file_metadata
      #
      # @return [Hash{Symbol=>any}]
      #
      def extract_file_metadata
        __ext_debug
        super
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Shrine::UploadedFile => Shrine::UploadedFileExt
override Shrine::UploadedFile => Shrine::UploadedFileDebug if DEBUG_SHRINE

__loading_end(__FILE__)
