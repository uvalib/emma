# app/helpers/file_name_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# FileNameHelper
#
module FileNameHelper

  def self.included(base)
    __included(base, '[FileNameHelper]')
  end

  include MimeHelper
  include DebugHelper

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Directory which holds cached copies of files.  In the absence of a
  # 'DOWNLOAD_DIR' environment variable, '/storage' is used.
  #
  # @type [String]
  #
  DOWNLOAD_DIR = ENV['DOWNLOAD_DIR'] || 'storage'

  NAME_PART_SEPARATOR = FileAttributes::NAME_PART_SEPARATOR
  FILE_ID_SEPARATOR   = FileAttributes::FILE_ID_SEPARATOR
  EXT_SEPARATOR       = FileAttributes::EXT_SEPARATOR

  # A mapping of file type to properties of the class which processes it.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  FF_PROPERTIES =
    FileFormat::FILE_FORMATS.map { |type|
      fmt = type.to_s.upcase_first
      fmt = "#{fmt}File".constantize rescue nil
      next unless fmt
      [type, { class: fmt, mimes: fmt.mime_types, exts: fmt.file_extensions }]
    }.compact.to_h.deep_freeze

  # A mapping of file type to the class which processes it.
  #
  # @type [Hash{Symbol=>Class}] with:
  #
  #   daisy:      DaisyFile
  #   daisyAudio: DaisyAudioFile
  #   epub:       EpubFile
  #   pdf:        PdfFile
  #   word:       WordFile
  #
  # @see DaisyAudioFile#initialize
  # @see DaisyFile#initialize
  # @see EpubFile#initialize
  # @see PdfFile#initialize
  # @see WordFile#initialize
  #
  FF_CLASS = FF_PROPERTIES.transform_values { |v| v[:class] }.freeze

  # A mapping of file type to related MIME types.
  #
  # @type [Hash{Symbol=>Array<String>}]
  #
  # @see DaisyAudioFile#MIME_TYPES
  # @see DaisyFile#MIME_TYPES
  # @see EpubFile#MIME_TYPES
  # @see PdfFile#MIME_TYPES
  # @see WordFile#MIME_TYPES
  #
  FF_MIMES = FF_PROPERTIES.transform_values { |v| v[:mimes] }.freeze

  # A mapping of file type to related file extensions.
  #
  # @type [Hash{Symbol=>Array<String>}]
  #
  # @see DaisyAudioFile#FILE_EXTENSIONS
  # @see DaisyFile#FILE_EXTENSIONS
  # @see EpubFile#FILE_EXTENSIONS
  # @see PdfFile#FILE_EXTENSIONS
  # @see WordFile#FILE_EXTENSIONS
  #
  FF_EXTS = FF_PROPERTIES.transform_values { |v| v[:exts] }.freeze

  # A mapping of MIME type to related format(s).
  #
  # @type [Hash{String=>Array<Symbol>}]
  #
  FF_MIME_TO_FMT =
    Hash.new.tap { |hash|
      FF_MIMES.each_pair do |type, mimes|
        mimes.each { |mime| (hash[mime] ||= []) << type }
      end
    }.deep_freeze

  # A mapping of file extension to related format(s).
  #
  # @type [Hash{String=>Array<Symbol>}]
  #
  FF_EXT_TO_FMT =
    Hash.new.tap { |hash|
      FF_EXTS.each_pair do |type, exts|
        exts.each { |ext| (hash[ext] ||= []) << type }
      end
    }.deep_freeze

  FORMAT_SUFFIXES   = FileFormat::FILE_FORMATS.map(&:to_s).deep_freeze
  FORMAT_EXTENSIONS = FF_EXT_TO_FMT.keys.freeze

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
    FF_EXT_TO_FMT[ext]&.first if ext &&= ext.to_s
  end

  # Map file format to (preferred) file extension.
  #
  # @param [Symbol, String] fmt
  #
  # @return [String]
  # @return [nil]
  #
  def fmt_to_ext(fmt)
    FF_EXTS[fmt]&.first if fmt &&= fmt.to_sym
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
    FF_MIME_TO_FMT[mime]&.first
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the value is a repository filename prefix.
  #
  # @param [String, Symbol] value
  #
  def repository_prefix?(value)
    EmmaRepository.values.include?(value.to_s)
  end

  # Indicate whether the value is a format filename suffix.
  #
  # @param [String, Symbol] value
  #
  def format_suffix?(value)
    FORMAT_SUFFIXES.include?(value.to_s)
  end

  # Indicate whether the value is a filename format extension.
  #
  # @param [String, Symbol] value
  #
  def format_extension?(value)
    FORMAT_EXTENSIONS.include?(value.to_s)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # extract_file_properties
  #
  # @overload extract_file_properties(src)
  #   @param [FileProperties, Hash] src
  #
  # @overload extract_file_properties(src, opt = nil)
  #   @param [String] src
  #   @param [Hash]   opt
  #
  # @return [FileProperties]
  #
  # == Usage Notes
  # If :repositoryId has the form of RemoteFile#download_path then neither
  # :repository nor :fmt need to be given -- they will be extracted from the
  # identifier value.  (However if :fmt *is* given, it will be used instead of
  # the extracted value.)
  #
  def extract_file_properties(src, opt = nil)
    __debug_args(binding)
    src, opt = [nil, src] if src.is_a?(Hash)
    opt = FileProperties.new(opt)

    # Parse URL or file path if provided.
    if src&.start_with?('http')
      opt.update!(parse_repository_path(src))
      src = nil
    elsif src.present?
      src = File.basename(src).presence
    end

    # Parse the filename or ID to extract additional information.
    src ||= opt[:repositoryId]
    prop  = parse_file_name(src)
    opt[:repositoryId] = prop[:repositoryId]

    # Return with values derived from the filename unless overridden by the
    # values provided via options.
    opt.update!(prop)
    opt[:fmt] ||= ext_to_fmt(opt[:ext])
    opt[:ext] ||= fmt_to_ext(opt[:fmt])
    FileProperties.new(opt, complete: true)
      .tap { |result| __debug_args(binding) { result } }
  end

  # parse_repository_path
  #
  # @param [String, URI] path
  #
  # @return [FileProperties]
  #
  # == Implementation Notes
  # NOTE: Lots of heuristics...
  #
  def parse_repository_path(path)
    fid = id = fmt = ext = nil
    uri = path.is_a?(URI) ? path : URI.parse(path.to_s)
    case uri.host.downcase.split('.')[-2]

      when 'archive'
        repo = 'internetArchive'
        name = uri.path.delete_prefix('/').delete_suffix('.zip')
        if ((ary = name.split('.')).size > 1) && format_extension?(ary.last)
          ext  = ary.pop
          name = ary.join('.')
          __debug { "... #{repo} ext_ = #{ext.inspect}" }
        end
        if ((ary = name.split('_')).size > 1) && format_suffix?(ary.last)
          fmt  = ary.pop
          name = ary.join('_')
          __debug { "... #{repo} fmt_ = #{fmt.inspect}" }
        end
        ary = name.split('/')
        __debug { "... #{repo} ary = #{ary.inspect}" }
        ary.shift if %w(download compress).include?(ary.first&.downcase)
        id  = ary.shift
        __debug { "... #{repo} id = #{id.inspect}" }
        while (v = ary.shift&.downcase)
          fmt ||= extract_query_options(v)[:formats] if v.include?('formats=')
        end

      when 'bookshare'
        repo = 'bookshare'
        opt  = extract_query_options(uri)
        id   = opt[:titleInstanceId]
        fmt  = opt[:downloadFormat]
        __debug { "... #{repo} opt = #{opt.inspect}" }

      when 'hathitrust'
        repo = 'hathiTrust'
        opt  = extract_query_options(uri)
        fid  = opt[:id].to_s.split(';').shift
        fmt  = File.basename(uri.path) # NOTE: Always(?) 'pdf'.
        __debug { "... #{repo} opt = #{opt.inspect}" }

      else
        repo = uri.host
        Log.warn { "#{__method__}: unknown repository #{repo.inspect}" }
        __debug { "... #{repo} opt = #{extract_query_options(uri).inspect}" }

    end
    FileProperties[repo, id, fid, fmt, ext]
      .tap { |result| __debug_args(binding) { result } }
  end

  # parse_file_name
  #
  # @param [String] name
  #
  # @return [FileProperties]
  #
  # == Implementation Notes
  # NOTE: Lots of heuristics...
  #
  def parse_file_name(name)
    parts = name.to_s.split(NAME_PART_SEPARATOR)
    repo  = fmt = ext = nil

    # Extract repository prefix from the filename.
    repo = parts.shift if (parts.size > 1) && repository_prefix?(parts.first)

    # Extract format suffix from the filename; otherwise scan the last name
    # component for a file extension.
    if (parts.size > 1) && format_suffix?(parts.last)
      fmt = parts.pop
      __debug { "... fmt => #{fmt.inspect}; parts = #{parts.inspect}" }
    elsif parts.last&.include?(EXT_SEPARATOR)
      ary = parts.pop.split(EXT_SEPARATOR)
      __debug { "... ary => #{ary.inspect}; parts = #{parts.inspect}" }
      if parts.present?
        fmt = ary.shift if format_suffix?(ary.first)
        ext = ary.join(EXT_SEPARATOR) unless ary.blank?
      elsif parts.blank?
        if format_extension?(ary.last)
          ext = ary.pop
        elsif known_extension?(ary.last)
          ary.pop
        end
        parts << ary.join(EXT_SEPARATOR) unless ary.blank?
      end
    end

    # The remaining part(s) are either the repository ID with a file ID or a
    # repository ID alone.  If :fileId was specified it will will be used in
    # place of an extracted file ID when constructing the root file name.
    id, fid = parts.join(NAME_PART_SEPARATOR).split(FILE_ID_SEPARATOR)

    FileProperties[repo, id, fid, fmt, ext]
      .tap { |result| __debug_args(binding) { result } }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # prepare_transfer_location
  #
  # @param [String, nil] dir          Original path of transfer location.
  #
  # @return [String]                  Final path of transfer location.
  #
  def prepare_transfer_location(dir)
    __debug_args(binding)
    dir = DOWNLOAD_DIR if dir.blank? || (dir == '/') || (dir == '.')
    FileUtils.mkpath(dir) unless File.directory?(dir)
    dir
  end

end

__loading_end(__FILE__)
