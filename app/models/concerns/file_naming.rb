# app/models/concerns/file_naming.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# FileNaming
#
module FileNaming

  include Emma::Mime

  # If *true*, only known file types are considered acceptable.
  #
  # @type [Boolean]
  #
  STRICT_FORMATS = true?(ENV_VAR['STRICT_FORMATS'])

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # noinspection RbsMissingTypeSignature
  class << self

    include FileFormat::Zip

    # Return the appropriate FileObject subclass based on the indicated type
    # and, if provided, the file contents.
    #
    # @param [Symbol, String]                          type
    # @param [FileHandle, IO, StringIO, Tempfile, nil] handle
    #
    # @return [Class, nil]
    #
    def format_class(type, handle = nil)
      type = daisy_type(type, handle) || type if handle
      type = type.to_s.upcase_first
      "FileObject::#{type}".safe_constantize
    end

    # Given a DAISY variant, scan its contents to determine which.
    #
    # This heuristic assumes that only distinction between "Daisy" and
    # "Daisy Audio" is the presence of sound files.
    #
    # @param [Symbol, String]                          type
    # @param [FileHandle, IO, StringIO, Tempfile, nil] handle
    #
    # @return [Symbol, nil]           Either :daisy or :daisyAudio
    #
    def daisy_type(type, handle)
      return unless %i[daisy daisyAudio].include?(type&.to_sym)
      return unless FileHandle.compatible?(handle)
      # noinspection RubyMismatchedArgumentType
      get_archive_entry('.mp3', handle) ? :daisyAudio : :daisy
    end

    # format_classes
    #
    # @return [Hash{Symbol=>Class}]
    #
    def format_classes
      @format_classes ||=
        FileFormat::TYPES.map { |type|
          fmt = format_class(type)
          [type, fmt] if fmt
        }.compact.to_h
    end

    # mime_types
    #
    # @return [Hash{Symbol=>Array<String>}]
    #
    def mime_types
      @mime_types ||= format_classes.transform_values(&:mime_types)
    end

    # file_extensions
    #
    # @return [Hash{Symbol=>Array<String>}]
    #
    def file_extensions
      @file_extensions ||= format_classes.transform_values(&:file_extensions)
    end

    # mime_to_fmt
    #
    # @return [Hash{String=>Array<Symbol>}]
    #
    def mime_to_fmt
      @mime_to_fmt ||=
        Hash.new.tap { |hash|
          mime_types.each_pair do |type, mimes|
            mimes.each { |mime| (hash[mime] ||= []) << type }
          end
        }.transform_values! { Array.wrap(_1).compact.sort.uniq }
    end

    # ext_to_fmt
    #
    # @return [Hash{String=>Array<Symbol>}]
    #
    def ext_to_fmt
      @ext_to_fmt ||=
        Hash.new.tap { |hash|
          file_extensions.each_pair do |type, exts|
            exts.each { |ext| (hash[ext] ||= []) << type }
          end
        }.transform_values! { Array.wrap(_1).compact.sort.uniq }
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Map extension to file format.
  #
  # @param [String, Symbol] ext
  #
  # @return [Symbol]
  # @return [nil]
  #
  def ext_to_fmt(ext)
    FileNaming.ext_to_fmt[ext]&.first if ext &&= ext.to_s
  end

  # Map file format to (preferred) file extension.
  #
  # @param [Symbol, String, nil] fmt
  #
  # @return [String]
  # @return [nil]
  #
  def fmt_to_ext(fmt)
    FileNaming.file_extensions[fmt.to_sym]&.first if fmt.present?
  end

  # Given a MIME type, return the associated upload format.
  #
  # @param [String, ActiveStorage::Attachment, nil] mime
  #
  # @return [Symbol]
  # @return [nil]
  #
  def mime_to_fmt(mime)
    mime = mime.content_type if mime.respond_to?(:content_type)
    FileNaming.mime_to_fmt[mime]&.first if mime.present?
  end

  # Map file format to (preferred) MIME type.
  #
  # @param [Symbol, String, nil] fmt
  #
  # @return [String]
  # @return [nil]
  #
  def fmt_to_mime(fmt)
    FileNaming.mime_types[fmt.to_sym]&.first if fmt.present?
  end

end

__loading_end(__FILE__)
