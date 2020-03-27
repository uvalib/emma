# app/models/concerns/file_naming.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# FileNaming
#
module FileNaming

  def self.included(base)
    __included(base, '[FileNaming]')
  end

  include Emma::Mime
  include Emma::Debug

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  class << self

    include ZipArchive

    # Create an instance of the appropriate FileObject subclass based on the
    # indicated type and, if provided, the file contents
    #
    # @param [Symbol, String] type
    # @param [IO]             io
    #
    # @return [Class, nil]
    #
    def format_class_instance(type, io = nil)
      if io.is_a?(IO)
        type = type.to_sym
        case type
          when :daisy, :daisyAudio
            # This heuristic assumes that only distinction between "Daisy" and
            # "Daisy Audio" is the presence of sound files.
            type = get_archive_entry('.mp3', io) ? :daisyAudio : :daisy
        end
      end
      format_class(type)&.dup
    end

    # format_class
    #
    # @param [Symbol, String] type
    #
    # @return [Class, nil]
    #
    def format_class(type)
      fmt = type.to_s.upcase_first
      "#{fmt}File".constantize rescue nil
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
        }.transform_values! { |types|
          Array.wrap(types).compact.sort.uniq
        }
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
        }.transform_values! { |types|
          Array.wrap(types).compact.sort.uniq
        }
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
  # @param [Symbol, String] fmt
  #
  # @return [String]
  # @return [nil]
  #
  def fmt_to_ext(fmt)
    FileNaming.file_extensions[fmt]&.first if fmt &&= fmt.to_sym
  end

  # Given a MIME type, return the associated upload format.
  #
  # @param [String, ActiveStorage::Attachment] item
  #
  # @return [Symbol]
  # @return [nil]
  #
  def mime_to_fmt(item)
    mime = item.respond_to?(:content_type) ? item.content_type : item
    FileNaming.mime_to_fmt[mime]&.first
  end

  # Map file format to (preferred) MIME type.
  #
  # @param [Symbol, String] fmt
  #
  # @return [String]
  # @return [nil]
  #
  def fmt_to_mime(fmt)
    FileNaming.mime_types[fmt]&.first if fmt &&= fmt.to_sym
  end

end

__loading_end(__FILE__)