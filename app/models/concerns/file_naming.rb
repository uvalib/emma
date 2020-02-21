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

  # Sections that support the notion of locally-downloaded copies of files from
  # repositories are made conditional on this setting.  This is an intermediate
  # step to removing/reworking those sections to use Shrine-based cached copies
  # of files (where feasible).
  #
  # @type [Boolean]
  #
  LOCAL_DOWNLOADS = false # TODO: Remove/rework sections marked with this.

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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the value is a format type.
  #
  # @param [String, Symbol] value
  #
  def format_type?(value)
    FileFormat::TYPES.include?(value&.to_sym)
  end

  # Indicate whether the value is a filename format extension.
  #
  # @param [String, Symbol] value
  #
  def format_extension?(value)
    FileNaming.ext_to_fmt.key?(value.to_s)
  end

if LOCAL_DOWNLOADS
  # Indicate whether the value is a repository filename prefix.
  #
  # @param [String, Symbol] value
  #
  def repository_prefix?(value)
    EmmaRepository.values.include?(value.to_s)
  end
end

if LOCAL_DOWNLOADS
  # Indicate whether the value is a format filename suffix.
  #
  # @param [String, Symbol] value
  #
  def format_suffix?(value)
    format_type?(value)
  end
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
  def extract_file_properties(src, opt = nil)
    __debug_args(binding)
    src, opt = [nil, src] if src.is_a?(Hash)
    opt = FileProperties.new(opt)

    if LOCAL_DOWNLOADS
      # Parse URL or file path if provided.
      if src&.start_with?('http')
        opt.update!(parse_repository_path(src))
        src = nil
      elsif src.present?
        src = File.basename(src).presence
      end

      # Parse the filename or ID to extract additional information.
      #
      # If :repositoryId has the form of RemoteFile#download_path then neither
      # :repository nor :fmt need to be given -- they will be extracted from
      # the identifier value.  (However if :fmt *is* given, it will be used
      # instead of the extracted value.)
      #
      src ||= opt[:repositoryId]
      prop  = parse_file_name(src)
      opt[:repositoryId] = prop[:repositoryId]

      # Return with values derived from the filename unless overridden by the
      # values provided via options.
      opt.update!(prop)
    end

    opt[:fmt] ||= ext_to_fmt(opt[:ext])
    opt[:ext] ||= fmt_to_ext(opt[:fmt])
    FileProperties.new(opt, complete: true)
      .tap { |result| __debug_args(binding) { result } }
  end

if LOCAL_DOWNLOADS
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
end

if LOCAL_DOWNLOADS
  NAME_PART_SEPARATOR = FileAttributes::NAME_PART_SEPARATOR
  FILE_ID_SEPARATOR   = FileAttributes::FILE_ID_SEPARATOR
  EXT_SEPARATOR       = FileAttributes::EXT_SEPARATOR
end

if LOCAL_DOWNLOADS
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
end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

if LOCAL_DOWNLOADS
  # Directory which holds cached copies of files.  In the absence of a
  # 'DOWNLOAD_DIR' environment variable, '/storage' is used.
  #
  # @type [String]
  #
  DOWNLOAD_DIR = ENV['DOWNLOAD_DIR'] || 'storage'
end

if LOCAL_DOWNLOADS
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

end

__loading_end(__FILE__)
