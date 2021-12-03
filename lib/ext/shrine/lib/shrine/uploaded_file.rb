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
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include Shrine::UploadedFile::InstanceMethods
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Bibliographic metadata and remediation information.
    #
    # @raise [Record::SubmitError]    @see #extract_file_metadata
    #
    # @return [Hash{Symbol=>*}]
    #
    def emma_metadata
      @emma_metadata ||= extract_file_metadata
    end

    # Parse the uploaded file to extract bibliographic metadata and remediation
    # information.
    #
    # @raise [Record::SubmitError]    If metadata was malformed.
    #
    # @return [Hash{Symbol=>*}]
    #
    def extract_file_metadata
      mime  = fmt = fmt_class = fmt_instance = fmt_parser = fmt_metadata = nil
      ext   = extension
      mime  = ext_to_mime(ext) || mime_type
      fmt   = (FileNaming.mime_to_fmt[mime]&.first if mime)
      fmt ||= (FileNaming.ext_to_fmt[ext]&.first   if ext)
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
        fmt = fmt_class = fmt_instance = fmt_parser = ''
        raise "#{__method__}: unknown mime #{mime.inspect}, ext #{ext.inspect}"
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
        error = Record::SubmitError.new(msg)
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
      unless ONLY_FOR_DOCUMENTATION
        # :nocov:
        include Shrine::UploadedFileExt
        # :nocov:
      end

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
      # @return [*]                   Return from block if block given.
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
      # @return [*]                   Return from block if block given.
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
      # @return [Tempfile]
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
      # @return [Hash{Symbol=>*}]
      #
      # This method overrides:
      # @see Shrine::UploadedFileExt#extract_file_metadata
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
