# app/models/concerns/remote_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for downloadable files.
#
# NOTE: This may be of limited use and might be removed at some point.
#
class RemoteFile < FileObject
if FileNaming::LOCAL_DOWNLOADS
  include HttpHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  FILE_RETRIES = 1
  HTTP_RETRIES = 3

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Actual URL source of the file object.
  #
  # @return [String, nil]
  #
  attr_reader :url

  # Latest error associated with the file object.
  #
  # @return [Exception, nil]
  #
  attr_reader :error

  # ===========================================================================
  # :section: FileObject overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [String, StringIO, IO] path
  # @param [Boolean]              fetch   Acquire file content immediately.
  # @param [Hash]                 opt
  #
  # This method overrides:
  # @see FileObject#initialize
  #
  def initialize(path, fetch: false, **opt)
    if path.present? # TODO: remove
      class_name = self.class.to_s
      class_name += ' (RemoteFile)' unless class_name == 'RemoteFile'
      __debug_args(binding, leader: "... NEW #{class_name}")
    end
    super(path, **opt)
    @url = @error = nil
    finalize if fetch && !path.is_a?(IO) && !path.is_a?(StringIO)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the instance is complete.
  #
  def finalized?
    downloaded?
  end

  # Indicate whether the instance includes acquired content.
  #
  def downloaded?
    @local_path.present?
  end

  # Complete the instance by acquiring its content if it was not already
  # acquired.
  #
  # @param [Boolean] force            If *true*, always get a fresh copy.
  #
  # @return [Boolean]
  #
  def finalize(force: false)
    local_path(force: force).present?
  end

  # Local file holding the downloaded file content.
  #
  # @param [Boolean] force            If *true*, always get a fresh copy.
  #
  # @return [String]                  Name of local copy of file content.
  # @return [IO]
  # @return [StringIO]
  # @return [nil]                     If file content could not be acquired.
  #
  # This method overrides:
  # @see FileAttributes#local_path
  #
  def local_path(force: false)
    if force
      @local_path = download(force: true)
    elsif !error
      @local_path ||= download(force: false)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Download a file.
  #
  # @param [Boolean] force            If *true*, always get a fresh copy.
  #
  # @return [String]                  File name for downloaded content.
  # @return [IO]
  # @return [StringIO]
  # @return [nil]                     If the file could not be acquired.
  #
  # == Usage Notes
  # If @path indicates a local file then @local_path will be set to the
  # location of the content specified by it.
  #
  # If @path is a URL, then @url will be set to the actual web location of the
  # content specified by it (by #download_file) and @local_path will be set to
  # the local copy of the content.
  #
  def download(force: false)
    __debug { "... DOWNLOAD | @path = #{@path.inspect} | @local_path = #{@local_path.inspect}" }
    file = @local_path || make_download_path(@path)
    here = file.is_a?(IO) || file.is_a?(StringIO)
    here ||= File.exists?(file) unless force
    here ? file : download_file(to: file)
  end

  # Get a file from a remote site.
  #
  # @overload download_file(to: nil, keep_tmp: nil)
  #   @param [String]       to        Destination; default: temp file.
  #   @param [Boolean, nil] keep_tmp  Default: *false*.
  #   @return [String, nil, *]
  #
  # @overload download_file(to: nil, as: :name, keep_tmp: true)
  #   @param [String]       to        Destination; default: temp file.
  #   @param [Symbol]       as        :name
  #   @param [Boolean, nil] keep_tmp  Default: *true* unless block given.
  #   @return [String, nil, *]        File name.
  #
  # @overload download_file(to: nil, as: :bytes, keep_tmp: false)
  #   @param [String]       to        Destination; default: temp file.
  #   @param [Symbol]       as        :bytes
  #   @param [Boolean, nil] keep_tmp  Default: *false*.
  #   @return [String, nil, *]        File contents
  #
  # @overload download_file(to: nil, as: :lines, keep_tmp: false)
  #   @param [String]       to        Destination; default: temp file.
  #   @param [Symbol]       as        :lines
  #   @param [Boolean, nil] keep_tmp  Default: *false*.
  #   @return [Array<String>, nil, *] Array of lines from file.
  #
  # @overload download_file(to: nil, as: :io, keep_tmp: true)
  #   @param [String]       to        Destination; default: temp file.
  #   @param [Symbol]       as        :io
  #   @param [Boolean, nil] keep_tmp  Default: *true* unless block given.
  #   @return [File, nil, *]          IO stream to the file.
  #
  # @yield result Pass the result to the block.
  # @yieldparam  [Array,String,File,nil] result
  # @yieldreturn [Array,String,File,nil]
  #
  # == Usage Notes
  # The temporary file used to receive the downloaded content will persist if
  # :as is :name or :io because it is assumed that the download was initiated
  # so that the caller may operate on the downloaded file content.  Otherwise,
  # the temporary file is automatically deleted because it is assumed that the
  # caller will operate directly on the content as returned by the method.
  #
  # However if a block is passed to the method, the temporary file will always
  # be removed.  Here it assumed that the caller will perform the necessary
  # operations within the block (including persisting the temporary file if
  # desired) and that the caller is only interested in the result of the block.
  #
  def download_file(to: nil, as: nil, keep_tmp: nil)
    @url = @error = tmp_file = result = nil
    __debug_args(binding)

    # Fetch the contents of the file from the specified URL, following
    # redirects if necessary.
    response = get_http(@path)
    content  = response.body
    raise 'no content' if content.blank?
    @url = response.headers['Location']

    # Save the contents to the named destination or a temporary file.
    file = to ? make_download_path(to) : (tmp_file = make_download_path(@path))
    File.open(file, 'wb') { |f| f.write(content) }

    # Return the expected value.  If :to is given and :as is not then it is
    # assumed the purpose of the method execution is to simply download the
    # file.
    as ||= to ? :name : :bytes
    result = (as == :name) ? file : get_file(file, as: as)
    if block_given?
      result = yield(result)
    elsif %i[name io].include?(as)
      keep_tmp = true if keep_tmp.nil?
    end

  rescue => e
    @error = e
    Log.warn { "#{__method__}: #{@path}: #{@error.message}" }

  ensure
    File.delete(tmp_file) if !keep_tmp && tmp_file && File.exist?(tmp_file)
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate a download file name.
  #
  # @param [String] path         Original path.
  #
  # @return [String]
  #
  def make_download_path(path)
    __debug_args(binding, leader: '...')
    self.class.make_download_path(path, get_file_attributes)
      .tap do |result|
      __debug_args(binding, "=> #{result.inspect}", leader: '...') {
        get_file_attributes
      }
    end
  end

  # Get a local file.
  #
  # @param [String]  path
  # @param [Symbol]  as               One of :io, :bytes, :lines.
  # @param [Integer] retries
  #
  # @return [Array<String>]           For as: :lines.
  # @return [String]                  For as: :bytes.
  # @return [File]                    For as: :io.
  # @return [nil]
  #
  def get_file(path, as: :bytes, retries: FILE_RETRIES)
    __debug_args(binding)
    case as
      when :io    then File.open(path, mode: 'rb')
      when :lines then File.readlines(path, chomp: true)
      else             File.read(path)
    end

  rescue => e
    Log.warn { "#{__method__}: #{path}: #{e.message}" }
    if retries > 0
      Log.debug { "#{__method__}: #{path}: retrying..." }
      retries -= 1
      retry
    else
      raise e
    end
  end

  # Get a remote file.
  #
  # @param [String]  url
  # @param [Integer] redirects
  #
  # @return [Faraday::Response]
  # @return [nil]
  #
  def get_http(url, redirects: HTTP_RETRIES)
    __debug_args(binding)
    url = CGI.unescape(url)
    # noinspection RubyArgCount
    while (response = connection.get(url, {}, accept: '*/*'))
      return response if response.status == 200
      raise "HTTP #{response.status}" unless redirect?(response.status)
      new_url = CGI.unescape(response.headers['Location'])
      raise 'HTTP redirect loop'      if new_url == url
      raise 'HTTP too many redirects' if (redirects -= 1) < 0
      url = new_url
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Connection options
  #
  # @return [Hash]
  #
  def options
    @options ||= {
      #timeout:      120, # TODO: was: 15,
      #open_timeout: 60,  # TODO: was: 5,
      timeout:      0.5, # TODO: was: 15,
      open_timeout: 0.5,  # TODO: was: 5,
    }
  end

  # Get a connection for making cached requests.
  #
  # @return [Faraday::Connection]
  #
  # @see ApiCachingMiddleWare#initialize
  #
  def connection
    @connection ||= make_connection
  end

  # Get a connection.
  #
  # @param [String, nil] url
  #
  # @return [Faraday::Connection]
  #
  def make_connection(url = nil)
    conn_opts = {
      #url:     url, #(url || @path),
      request: options.slice(:timeout, :open_timeout),
      ssl:     { verify: false }, # TODO: keep?
    }
    conn_opts[:url] = url if url.present?
    conn_opts[:request][:params_encoder] ||= Faraday::FlatParamsEncoder

    retry_opt = {
      max:                 options[:retry_after_limit],
      interval:            0.05,
      interval_randomness: 0.5,
      backoff_factor:      2,
    }

    Faraday.new(conn_opts) do |bld|
      bld.use      :instrumentation
      bld.request  :retry,  retry_opt
      bld.response :logger, Log.logger
      bld.response :raise_error
      bld.adapter  options[:adapter] || Faraday.default_adapter
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  module ClassMethods

    # Generate a download file path.
    #
    # @overload make_download_path(path)
    #   @param [FileProperties, Hash] path
    #   @return [String]
    #
    # @overload make_download_path(path)
    #   @param [String]               path  Original path.
    #   @param [FileProperties, Hash] opt
    #   @return [String]
    #
    # @overload make_download_path(path)
    #   @param [IO]                   path  Open file instance.
    #   @param [FileProperties, Hash] opt
    #   @return [String]
    #
    # @overload make_download_path(path)
    #   @param [StringIO]             path
    #   @param [FileProperties, Hash] opt
    #   @return [String]
    #
    # @see FileObject#make_file_name
    #
    def make_download_path(path, opt = nil)
      __debug_args(binding)
      path, opt = [nil, path] if path.is_a?(Hash)
      return path.path if path.is_a?(IO) && path.path.present?
      prop = FileProperties.new(opt)
      if path.blank? || path.is_a?(StringIO)
        file = make_file_name(**prop)
        dir  = nil
      elsif path.start_with?('http')
        prop = extract_file_properties(path, prop)
        file = prop.filename
        dir  = nil
      else
        path = path.split('/')
        file = make_file_name(path.pop, **prop)
        dir  = path.join('/')
      end
      dir = prepare_transfer_location(dir)
      File.join(dir, file)
    end

  end

  extend ClassMethods
end
end

__loading_end(__FILE__)
