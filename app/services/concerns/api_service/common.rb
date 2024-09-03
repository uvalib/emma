# app/services/concerns/api_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Service implementation methods.
#
module ApiService::Common

  include Emma::Common
  include Emma::Debug

  include ApiService::Properties
  include ApiService::Exceptions
  include ApiService::Identity

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The HTTP verb for the last #api access.
  #
  # @return [Symbol, nil]
  #
  attr_reader :verb

  # The URL path for the last #api access.
  #
  # @return [String, nil]
  #
  attr_reader :action

  # The URL parameters for the last #api access.
  #
  # @return [Hash, nil]
  #
  attr_reader :params

  # The API endpoint response generated by the last #api access.
  #
  # @return [Faraday::Response, nil]
  #
  attr_reader :response

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The HTTP method of the latest API request.
  #
  # @param [Symbol, String, nil] http_method
  #
  # @return [String]
  #
  #--
  # === Variations
  #++
  #
  # @overload request_type()
  #   @return [String]                      Type derived from @verb.
  #
  # @overload request_type(http_method)
  #   @param [Symbol, String] http_method
  #   @return [String]                      Type derived from *http_method*.
  #
  def request_type(http_method = nil)
    (http_method || @verb).to_s.upcase
  end

  # Indicate whether the latest API request is an update (PUT, POST, or PATCH).
  #
  # @param [Symbol, String, nil] http_method
  #
  #--
  # === Variations
  #++
  #
  # @overload update_request?()
  #   Return whether @verb is an update.
  #
  # @overload update_request?(http_method)
  #   Return whether *http_method* is an update.
  #   @param [Symbol, String] http_method
  #
  def update_request?(http_method = nil)
    http_method = http_method.downcase.to_sym if http_method.is_a?(String)
    %i[put post patch].include?(http_method || @verb)
  end

  # Most recently invoked HTTP request URL.
  #
  # @param [Hash, nil] prm
  #
  # @return [String]
  #
  #--
  # === Variations
  #++
  #
  # @overload latest_endpoint(complete: false)
  #   Get the URL derived from @params.
  #   @param [Boolean] complete       If *true* return :api_key parameter.
  #
  # @overload latest_endpoint(hash, complete: false)
  #   Get the URL derived from provided *hash*.
  #   @param [Hash]    hash           Parameters to check instead of @params.
  #   @param [Boolean] complete       If *true* return :api_key parameter.
  #
  def latest_endpoint(prm = nil)
    prm = (prm || @params).dup
    prm.delete(:api_key) unless prm.delete(:complete)
    # noinspection RubyMismatchedArgumentType
    prm = url_query(prm).presence
    [@action, prm].compact.join('?')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get data from the API and update @response.
  #
  # @param [Symbol, String]           verb  One of :get, :post, :put, :delete
  # @param [Array<String,ScalarType>] args  Path components of the API request.
  # @param [Hash]                     opt   API request parameters except for:
  #
  # @option opt [Symbol]  :meth           The calling method for logging.
  # @option opt [Boolean] :fatal          If *true*, set @exception but do not
  #                                         raise it.
  # @option opt [Boolean] :no_exception   If *true*, neither set @exception nor
  #                                         raise it.
  #
  # @raise [ApiService::Error]
  #
  # @return [Faraday::Response, nil]
  #
  # === Usage Notes
  # Clears and/or sets @exception as a side-effect.
  #
  #--
  # noinspection RubyScope, RubyMismatchedArgumentType
  #++
  def api(verb, *args, **opt)
    clear_error
    @action = @response = error = nil
    @verb   = verb.to_s.downcase.to_sym

    # Set internal options from parameters or service options.
    @params      = opt.slice!(:meth, *SERVICE_OPT)
    no_exception = opt[:no_exception] || options[:no_exception]
    fatal        = opt[:fatal]        || options[:fatal] || !no_exception
    meth         = opt[:meth]         || calling_method

    # Form the API path from arguments, build API call parameters (minus
    # internal options), prepare HTTP headers according to the HTTP method,
    # then send the API request.
    @action = api_path(*args)
    @params = api_options(@params)
    options, headers, body = api_headers(@params)
      .tap { |parts| __debug_api_headers(*parts) }
    if body.present?
      @action = make_path(@action, **options) if options.present?
      options = body
    end
    transmit(@verb, @action, options, headers, **opt)

  rescue => error
    re_raise_if_internal_exception(error)
    set_error(error)

  ensure
    __debug_api_response(error: error) unless is_a?(SearchService)
    log_exception(error, meth: meth)   if error
    clear_error                        if no_exception
    raise exception                    if exception && fatal
    return (@response unless error)
  end

  # Construct a message to be returned from the method that executed :api.
  # This provides a uniform call for initializing the object with information
  # needed to build the object to return, including error information.
  #
  # @param [Class<Api::Record>] type
  # @param [Array] args   Additional values for the *type* initializer.
  # @param [Hash]  opt    Additional values for the *type* initializer.
  #
  def api_return(type, *args, **opt)
    opt[:error] = exception if exception
    type.new(response, *args, **opt)
  end

  # Retrieve a copy of a file and download it to the browser.
  #
  # @param [ActionDispatch::Response] response  Client response object.
  # @param [String, nil]              url       Default: `#base_url`.
  # @param [Hash]                     headers   Header additions/overrides.
  # @param [Boolean, nil]             new_tab   If *true* open new browser tab.
  # @param [Symbol, nil]              meth      Unused unless DEBUG_DOWNLOAD.
  # @param [Hash]                     opt       Passed to #make_path.
  #
  # @return [void]
  #
  # @see ActionDispatch::Response
  #
  # === Implementation Notes
  # This is essentially a placeholder that will require work to actually cause
  # the results to be sent in chunks to the browser as they are received from
  # the remote system.
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def api_download(response, url: nil, headers: {}, new_tab: false, meth: nil, **opt)
    total_size = group_size = chunks = start_time = total_duration = 0
    show_value = show_line = show_chunks = debug_chunks = nil
    if DEBUG_DOWNLOAD
      meth      ||= __method__
      show_line   = ->(line) { $stderr.puts "=== #{meth} #{line}" }
      show_value  = ->(k, v) { show_line.("#{k} = #{v}") }
      show_chunks = ->(*parts) {
        old_total = total_duration
        total_sec = 'total %.2f sec' % (total_duration = Time.now - start_time)
        chunk_sec = '%.2f sec'       % (total_duration - old_total)
        parts     = ["#{group_size} bytes", chunk_sec, total_sec, *parts]
        show_line.("chunks to #{chunks}: %s" % parts.join('; '))
        total_size += group_size
        group_size = 0
      }
      debug_chunks = ->(chunk) {
        group_size += chunk.size
        show_chunks.() if ((chunks += 1) % 100).zero?
      }
    end
    _, hdrs, _ = api_headers({})
    options = api_options({}).transform_values { |v| url_escape(v) }
    headers = hdrs.merge(headers) if hdrs.present?
    opt = options.merge(opt)      if options.present?
    uri = url ? URI.parse(url) : base_uri
    Net::HTTP.start(uri.hostname) do |http|
      url = make_path((url || base_url), **opt)
      req = Net::HTTP::Get.new(url, headers)
      if DEBUG_DOWNLOAD
        {
          url:          url,
          req:          req,
          'req.method': req.method,
          'req.path':   req.path,
          'req.uri':    req.uri,
          'req.header': req.to_hash,
        }.each_pair { |k, v| show_value.(k, v) }
        start_time = Time.current
      end
      http.request(req) do |remote_response|
        if DEBUG_DOWNLOAD
          { remote: remote_response, client: response }.each do |k, v|
            show_line.("#{k} = #{v.inspect} = #{v.header.inspect}")
          end
        end
        header_defaults = {
          'Content-Disposition' => (new_tab ? 'attachment' : 'inline'),
          'Content-Type'        => 'application/octet-stream',
        }.each_pair do |h, default|
          response[h] = remote_response[h] || default
        end
        if DEBUG_DOWNLOAD
          msgs = { remote: remote_response, client: response }
          header_defaults.each_key do |h|
            msgs.each_pair { |k, v| show_value.("#{k}[#{h}]", k[h]) }
          end
        end
        remote_response.read_body do |chunk|
          debug_chunks&.(chunk)
          response.write(chunk)
        end
      end
    end
  ensure
    show_chunks&.("#{total_size + group_size} bytes")
    response.close
  end

  # Local options for #api_download.
  #
  # @type [Array<Symbol>]
  #
  API_DOWNLOAD_OPT = method_key_params(:api_download).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # HTTP ports which do not need to be explicitly included when generating an
  # absolute path.
  #
  # @type [Array<Integer>]
  #
  COMMON_PORTS = [URI::HTTPS::DEFAULT_PORT, URI::HTTP::DEFAULT_PORT].freeze

  # Form a normalized API path from one or more path fragments.
  #
  # If *args* represents a full path which is different than `#base_url` then
  # an absolute path is returned.  Otherwise, `#base_uri`.path exists, the
  # resultant full or partial path may be modified to ensure that it is
  # included exactly once.
  #
  # @param [Array<String,Array>] args
  #
  # @return [String]
  #
  def api_path(*args)
    arg   = args.flatten.join('/').strip
    uri   = URI.parse(arg)
    base  = base_uri.path&.split('/')&.compact_blank!&.presence
    path  = uri.path&.split('/')&.compact_blank!&.presence
    path.shift(base.size) if path && base && (path.first(base.size) == base)
    ver   = api_version.presence
    ver   = nil if ver && (base&.include?(ver) || path&.include?(ver))
    qry   = uri.query.presence
    qry &&= "?#{qry}"
    if (host = uri.host).present?
      rel = (host == base_uri.host)
      sch = uri.scheme.presence || (base_uri.scheme.presence if rel) || 'https'
      prt = uri.port.presence   || (base_uri.port.presence   if rel)
      prt = nil if prt && COMMON_PORTS.include?(prt)
      url = [sch, "//#{host}", prt].compact.join(':')
    else
      url = base = nil
    end
    [url, *base, ver, *path, qry].compact.join('/')
  end

  # Add service-specific API options.
  #
  # @param [Hash, nil] params         Default: @params.
  #
  # @return [Hash]                    New API parameters.
  #
  # === Usage Notes
  # If overridden, this should be called first via 'super'.
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def api_options(params = nil)
    params = @params if params.nil?
    params = params.except(*IGNORED_PARAMETERS)
    params = decode_parameters!(params)
    api_key ? params.merge!(api_key: api_key) : params
  end

  # Determine whether the HTTP method indicates a write rather than a read and
  # prepare the HTTP headers accordingly.
  #
  # @param [Hash, nil]         params   Default: @params.
  # @param [Hash, nil]         headers  Default: {}.
  # @param [String, Hash, nil] body     Default: nil unless `#update_request?`.
  #
  # @return [Array(Hash,Hash,String)]   Message body plus headers for GET.
  # @return [Array(Hash,Hash,Hash)]     Query plus headers for PUT, POST, PATCH
  #
  def api_headers(params = nil, headers = nil, body = nil)
    params  ||= @params
    headers ||= {}
    if params.key?(:body)
      body  ||= params[:body]
      params  = params.except(:body)
    elsif body.nil? && update_request?
      body    = params
      params  = {}
    end
    if body
      body = body.is_a?(Array) ? body.map { |v| api_body(v) } : api_body(body)
      body = body.to_json
      headers = headers.merge('Content-Type' => 'application/json')
    end
    return params, headers, body
  end

  # Process a message body component into a form ready for conversion to JSON.
  #
  # @param [any, nil] obj             Hash, String
  #
  # @return [Hash, String, any, nil]
  #
  def api_body(obj)
    obj = obj.as_json unless obj.is_a?(String)
    obj.is_a?(Hash) ? reject_blanks(obj) : obj
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

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
  # @param [String, nil] url          Default: `#base_url`
  # @param [Hash]        opt          Passed to Faraday#initialize except
  #                                     opt[:retry] which is passed to
  #                                     Faraday#request.
  #
  # @return [Faraday::Connection]
  #
  def make_connection(url = nil, **opt)
    conn_opt = {
      url: (url || base_url),
      request: {
        timeout:        options[:timeout],
        open_timeout:   options[:open_timeout],
        params_encoder: options[:params_encoder] || Faraday::FlatParamsEncoder
      },
      retry:   {
        max:                 options[:retry_after_limit],
        interval:            0.05,
        interval_randomness: 0.5,
        backoff_factor:      2,
      }
    }
    conn_opt.deep_merge!(opt) if opt.present?
    token     = conn_opt.delete(:token) || access_token
    retry_opt = conn_opt.delete(:retry)
    logger    = conn_opt.delete(:logger) || ApiService.api_logger

    Faraday.new(conn_opt) do |bld|
      bld.use      :instrumentation
      bld.use      :api_caching_middleware          if CACHING
      bld.request  :authorization, 'Bearer', token  if token.present?
      bld.request  :retry,  retry_opt
      bld.response :logger, logger
      bld.adapter  options[:adapter] || Faraday.default_adapter
    end
  end

  # Send an API request.
  #
  # @param [Symbol]            verb
  # @param [String]            action
  # @param [Hash, String, nil] params
  # @param [Hash, nil]         headers
  # @param [Hash]              opt
  #
  # @option opt [Boolean]      :no_redirect
  # @option opt [Integer, nil] :redirection
  #
  # @raise [ApiService::EmptyResultError]
  # @raise [ApiService::HtmlResultError]
  # @raise [ApiService::RedirectionError]
  # @raise [ApiService::Error]
  #
  # @return [Faraday::Response]
  # @return [nil]
  #
  # === Usage Notes
  # Sets @response as a side-effect.
  #
  def transmit(verb, action, params, headers, **opt)
    redirect  = nil
    @response = connection.send(verb, action, params, headers)
    raise empty_result_error if @response.nil?

    case @response.status
      when 202, 204
        # No response body expected.
      when 200..299
        result = @response.body
        raise empty_result_error(@response) if result.blank?
        raise html_result_error(@response)  if result =~ /\A\s*<[^?]/
      when 301, 303, 308, 302, 307
        redirect = @response['Location'] || ''
      when 400..499
        raise request_error(@response)
      else
        raise response_error(@response)
    end

    if redirect.nil? || opt[:no_redirect] || options[:no_redirect]
      @response
    elsif redirect.blank?
      raise redirect_error(@response)
    elsif (pass = opt[:redirection].to_i) >= max_redirects
      raise redirect_limit_error
    else
      opt[:redirection] = (pass += 1)
      __debug_line(leader: '!!!') do
        [service_name] << "REDIRECT #{pass} TO #{redirect.inspect}"
      end
      transmit(:get, redirect, params, headers, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Extract API parameters from *opt*.
  #
  # @param [Symbol]  meth             Calling method.
  # @param [Boolean] check_req        Check for missing required keys.
  # @param [Boolean] check_opt        Check for extra optional keys.
  # @param [Hash]    opt
  #
  # @raise [RuntimeError]             Errors and #RAISE_ON_INVALID_PARAMS true.
  #
  # @return [Hash]                    Just the API parameters from *opt*.
  #
  def get_parameters(meth, check_req: true, check_opt: false, **opt)
    properties     = api_methods(meth)
    errors         = properties ? [] : ['unregistered API method']
    properties   ||= {}
    multi          = Array.wrap(properties[:multi])
    key_alias      = properties[:alias] || {}
    required_keys  = required_parameters(meth)
    optional_keys  = optional_parameters(meth)
    specified_keys =
      [].concat(required_keys, optional_keys, key_alias.keys, SERVICE_OPT)

    # Validate the keys provided.
    if check_req && (missing_keys = required_keys - opt.keys).present?
      parameters = 'parameter'.pluralize(missing_keys.size)
      keys       = missing_keys.join(', ')
      errors << "missing API #{parameters} #{keys}"
    end
    if check_opt && (extra_keys = opt.keys - specified_keys).present?
      parameters = 'parameter'.pluralize(extra_keys.size)
      keys       = extra_keys.join(', ')
      errors << "invalid API #{parameters} #{keys}"
    end
    invalid_params(meth, *errors) if errors.present?

    # Return with the options needed for the API request.
    # @type [Symbol]   k
    # @type [any, nil] v
    opt.slice(*specified_keys).map { |k, v|
      v = v.first if v.is_a?(Array) && !v.many?
      next if v.blank?
      k = key_alias[k] || k
      v = quote(v, separator: ' ') if v.is_a?(Array) && !multi.include?(k)
      k = encode_parameter(k)
      [k, v]
    }.compact.to_h
  end

  # Preserve a key that would be mistaken for an ignored system parameter.
  #
  # @param [Symbol] key
  #
  # @return [Symbol]
  #
  def encode_parameter(key)
    IGNORED_PARAMETERS.include?(key) ? "_#{key}".to_sym : key
  end

  # Preserve keys that would be mistaken for an ignored system parameter.
  #
  # @param [Hash] prm
  #
  # @return [Hash]                    A modified copy of *prm*.
  #
  def encode_parameters(**prm)
    encode_parameters!(prm)
  end

  # Preserve keys that would be mistaken for an ignored system parameter.
  #
  # @param [Hash] prm
  #
  # @return [Hash]                    The original *prm* now modified.
  #
  def encode_parameters!(prm)
    prm.transform_keys! { |k| encode_parameter(k) }
  end

  # Reverse the transform of #encode_parameter.
  #
  # @param [Symbol] key
  #
  # @return [Symbol]
  #
  def decode_parameter(key)
    key.to_s.sub(/^_/, '').to_sym
  end

  # Restore preserved keys.
  #
  # @param [Hash] prm
  #
  # @return [Hash]                    A modified copy of *prm*.
  #
  def decode_parameters(**prm)
    decode_parameters!(prm)
  end

  # Restore preserved keys.
  #
  # @param [Hash] prm
  #
  # @return [Hash]                    The original *prm* now modified.
  #
  def decode_parameters!(prm)
    prm.transform_keys! { |k| decode_parameter(k) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Report on errors in parameters supplied to an API method.
  #
  # @param [String, Symbol] meth
  # @param [Array<String>]  errors
  # @param [Boolean]        fatal
  #
  # @raise [RuntimeError]             Errors present and *fatal* is *true*.
  #
  # @return [nil]                     No errors or *fatal* is *false*.
  #
  def invalid_params(meth, *errors, fatal: RAISE_ON_INVALID_PARAMS)
    return if errors.blank?
    errors.each { |problem| Log.warn("#{meth}: #{problem}") }
    raise RuntimeError, ("#{meth}: " + errors.join("\nAND ")) if fatal
  end

  # ===========================================================================
  # :section: Debugging
  # ===========================================================================

  protected

  # __debug_api_headers
  #
  # @param [Hash, nil]         options
  # @param [Hash, nil]         headers
  # @param [Hash, String, nil] body
  # @param [Symbol, nil]       action
  # @param [Boolean]           full     If *true*, show complete body.
  #
  # @return [void]
  #
  # @see #api_headers
  #
  def __debug_api_headers(
    options,
    headers,
    body,
    action: @action,
    full:   DEBUG_TRANSMISSION
  )
    opts_hdrs = { options: options, headers: headers }
    opts_hdrs.transform_values! { |v| v&.inspect || '(none)' }
    body = "BODY:\n#{body.presence&.pretty_inspect}"
    opt  = full ? { max: nil } : {}
    # noinspection RubyMismatchedArgumentType
    __debug_impl(leader: '>>>', separator: DEBUG_SEPARATOR, **opt) do
      [service_name] << action.inspect << opts_hdrs << body
    end
  end

  # __debug_api_response
  #
  # @param [Faraday::Response,Hash] response
  # @param [Exception]              error
  # @param [Symbol,String]          action
  # @param [Boolean]                full      If *true*, show complete body.
  # @param [Integer, nil]           limit     Max data output size.
  #
  # @return [void]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def __debug_api_response(
    response: @response,
    error:    @exception,
    action:   @action,
    full:     DEBUG_TRANSMISSION,
    limit:    2048
  )
    response ||= error.try(:http_response) || error.try(:response)

    status = ExecReport.http_status(error) || ExecReport.http_status(response)
    status = { status: status, error: error }
    status[:'@exception'] = @exception unless error == @exception
    status.transform_values! { |v| v&.inspect || '(none)' }
    status.transform_values! { |v| v.truncate(256) } unless full

    if (data = ApiService::Error.oauth2_error_header(response))
      data = "(www-authenticate) #{data}"
    elsif (data = response.try(:body) || response.try(:dig, :body)).blank?
      data = '(none)'
    else
      size = data.is_a?(String) ? "#{data.size} bytes" : data.class
      data = data.pretty_inspect unless data.is_a?(String)
      data = data.truncate_bytes(limit) rescue nil if limit&.positive?
      data = data ? "#{size}:\n#{data}" : "#{size} [...]"
    end

    __debug_impl(leader: '<<<', separator: DEBUG_SEPARATOR, max: nil) do
      # noinspection RubyMismatchedArgumentType
      [service_name] << action.inspect << status << "DATA: #{data}"
    end
  end

  unless CONSOLE_DEBUGGING || DEBUG_TRANSMISSION
    neutralize(:__debug_api_headers, :__debug_api_response)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.include(ApiService::Definition)
  end

end

__loading_end(__FILE__)
