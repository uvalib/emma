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

    include Shrine::UploadedFile::InstanceMethods

    include FileNaming

    # =========================================================================
    # :section: Shrine::UploadedFile overrides
    # =========================================================================

    public

    # Returns serializable hash representation of the uploaded file.
    #
    # @return [Hash{String=>*}]
    #
    # This method overrides:
    # @see Shrine::UploadedFile::InstanceMethods#data
    #
    def data
      super.merge('emma_data' => emma_metadata.deep_stringify_keys)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Bibliographic metadata and remediation information.
    #
    # @return [Hash{Symbol=>*}]
    #
    def emma_metadata
      @emma_metadata ||= extract_file_metadata
    end

    # Parse the uploaded file to extract bibliographic metadata and remediation
    # information.
    #
    # @return [Hash{Symbol=>*}]
    #
    def extract_file_metadata
      fmt_class = fmt_instance = fmt_parser = mime = fmt = nil
      ext  = extension
      mime = ext_to_mime(ext)  || mime_type
      fmt  = mime_to_fmt(mime) || ext_to_fmt(ext)
      raise if fmt.nil?
      metadata.merge!('mime_type' => mime)
      fmt_class    = FileNaming.format_class_instance(fmt, io)
      fmt_instance = fmt_class.new(io)
      fmt_parser   = fmt_instance.parser
      fmt_metadata = fmt_parser.common_metadata
      fmt_metadata[:dc_format] = fmt_instance.fmt
      reject_blanks(fmt_metadata)

    rescue => e
      Log.debug { "#{__method__}: #{e.class}: #{e.message}" }
      error =
        if fmt.nil? || fmt_class.nil?
          "#{mime.inspect} is not a recognized file type"
        elsif fmt_instance.nil?
          "Could not create #{fmt.inspect} analyzer"
        elsif fmt_parser.nil?
          "Could not create #{fmt.inspect} parser"
        else
          "Could not extract #{fmt.inspect} metadata"
        end
      raise UploadConcern::SubmitError, error

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Shrine::UploadedFile => Shrine::UploadedFileExt

__loading_end(__FILE__)
