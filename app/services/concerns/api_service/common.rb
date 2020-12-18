# app/services/concerns/api_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/https'
require 'faraday'

# ApiService::Common
#
module ApiService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, ApiService::Definition)
  end

  include Emma::Common
  include Emma::Debug
  include ApiService::Properties

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

  # The HTTP method of the latest API request.
  #
  # @param [Symbol, String, nil] http_method
  #
  # @return [String]
  #
  # == Variations
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
  # == Variations
  #
  # @overload update_request?()
  #   Return whether @verb is an update.
  #
  # @overload update_request?(http_method)
  #   Return whether *http_method* is an update.
  #   @param [Symbol, String] http_method
  #
  def update_request?(http_method = nil)
    # noinspection RubyNilAnalysis
    http_method = http_method.downcase.to_sym if http_method.is_a?(String)
    %i[put post patch].include?(http_method || @verb)
  end

  # Most recently invoked HTTP request URL.
  #
  # @param [Hash, nil] opt
  #
  # @return [String]
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
  #--
  # noinspection RubyNilAnalysis, RubyYardParamTypeMatch
  #++
  def latest_endpoint(opt = nil)
    opt = (opt || @params).dup
    opt.delete(:api_key) unless opt.delete(:complete)
    opt = url_query(opt).presence
    [@action, opt].compact.join('?')
  end

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  public

  # The exception raised by the last #api access.
  #
  # @return [Exception, nil]
  #
  attr_reader :exception

  # Indicate whether the latest API request generated an exception.
  #
  def error?
    @exception.present?
  end

  # The message associated with the latest API exception.
  #
  # @return [String]
  # @return [nil]                     If there is no exception.
  #
  def error_message
    @exception&.message
  end

  # Cause an exception to be ignored to avoid generation of a flash message.
  #
  # @return [void]
  #
  # @see SessionConcern#session_update
  #
  def discard_exception
    @exception = nil
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  public

  # The user that invoked #api.
  #
  # @return [User, nil]
  #
  attr_reader :user

  # Extract the user name to be used for API parameters.
  #
  # @param [User, String] user
  #
  # @return [String]
  #
  def name_of(user)
    user.to_s
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  protected

  # Set the user for the current session.
  #
  # @param [User, nil] u
  #
  # @raise [StandardError]            If *u* is invalid.
  #
  # @return [void]
  #
  def set_user(u)
    raise "argument must be a User not a #{u.class}" if u && !u.is_a?(User)
    @user = u
  end

  # The current OAuth2 access bearer token.
  #
  # @return [String]
  # @return [nil]                     If there is no @user.
  #
  def access_token
    @user&.access_token
  end

  # The current OAuth2 refresher token.
  #
  # @return [String]
  # @return [nil]                     If there is no @user.
  #
  def refresh_token
    @user&.refresh_token
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
  # @option opt [Boolean] :no_raise       If *true*, set @exception but do not
  #                                         raise it.
  # @option opt [Boolean] :no_exception   If *true*, neither set @exception nor
  #                                         raise it.
  #
  # @raise [ApiService::Error]
  #
  # @return [Faraday::Response]
  #
  #--
  # noinspection RubyScope
  #++
  def api(verb, *args, **opt)
    @action = @response = @exception = error = nil
    @verb   = verb.to_s.downcase.to_sym

    # Set internal options from parameters or service options.
    opt, @params = partition_options(opt, :meth, *SERVICE_OPTIONS)
    no_exception = opt[:no_exception] || options[:no_exception]
    no_raise     = opt[:no_raise]     || options[:no_raise] || no_exception
    meth         = opt[:meth]         || calling_method

    # Form the API path from arguments, build API call parameters (minus
    # internal options), prepare HTTP headers according to the HTTP method,
    # then send the API request.
    @action = api_path(*args)
    @params = api_options(@params)
    options, headers, body = api_headers(@params)
    __debug_line(leader: '>>>') do
      [service_name] << @action.inspect << {}.tap do |details|
        details[:options] = options.inspect if options.present?
        details[:headers] = headers.inspect if headers.present?
        details[:body]    = body.inspect    if body.present?
      end
    end
    if body.present?
      @action = make_path(@action, options) if options.present?
      options = body
    end
    @response = transmit(@verb, @action, options, headers, **opt)

  rescue Api::Error => error
    @exception = error

  rescue Faraday::ConnectionFailed, Net::OpenTimeout => error
    @exception = connect_error(error)

  rescue Faraday::TimeoutError, Net::ReadTimeout, Net::WriteTimeout => error
    @exception = timeout_error(error)

  rescue Faraday::ServerError => error
    @exception = response_error(error)

  rescue Faraday::UnauthorizedError, Faraday::ProxyAuthError => error
    @exception = auth_error(error)

  rescue Faraday::ParsingError => error
    @exception = parse_error(error)

  rescue Faraday::ClientError => error
    @exception = request_error(error)

  rescue => error
    @exception = response_error(error)

  ensure
    log_exception(error, meth: meth) if error
    __debug_line(leader: '<<<') do
      # noinspection RubyNilAnalysis
      resp = error.respond_to?(:response) && error.response || @response
      stat = data = nil
      if resp
        stat ||= resp.http_status if resp.respond_to?(:http_status)
        stat ||= resp.status      if resp.respond_to?(:status)
        data ||= resp.body        if resp.respond_to?(:body)
      end
      if resp.respond_to?(:dig)
        stat ||= resp[:http_status]
        stat ||= resp[:status]
        data ||= resp[:body]
      end
      [service_name] << @action.inspect << {
        status: stat || '?',
        data:   data || '?',
        error:  error,
      }.transform_values { |v| v.inspect.truncate(256) }
    end
    @response  = nil if error
    @exception = nil if no_exception
    raise @exception unless no_raise || @exception.nil?
    return @response
  end

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
  # an absolute path is returned.
  #
  # @param [Array<String,Array>] args
  #
  # @return [String]
  #
  def api_path(*args)
    args   = args.flatten.join('/').strip
    uri    = URI.parse(args)
    qry    = uri.query.presence
    path   = uri.path&.squeeze('/') || ''
    path   = "/#{path}" unless path.start_with?('/')
    ver    = api_version.presence
    ver  &&= "/#{ver}"
    result = []
    if (host = uri.host).present? && (host != base_uri.host)
      scheme = uri.scheme || 'https'
      port   = uri.port
      result << scheme << '://' << host
      result << ':' << port if port && !COMMON_PORTS.include?(port)
    end
    result << ver unless (path == ver) || path.start_with?("#{ver}/")
    result << path
    result << '?' << qry if qry
    result.compact.join
  end

  # Add service-specific API options.
  #
  # @param [Hash, nil] params         Default: @params.
  #
  # @return [Hash]                    New API parameters.
  #
  # == Usage Notes
  # If overridden, this should be called first via 'super'.
  #
  #--
  # noinspection RubyNilAnalysis, RubyYardParamTypeMatch, RubyYardReturnMatch
  #++
  def api_options(params = nil)
    params ||= @params
    params = params.reject { |k, _| IGNORED_PARAMETERS.include?(k) }
    decode_parameters!(params)
    params[:api_key] = api_key if api_key
    params
  end

  # Determine whether the HTTP method indicates a write rather than a read and
  # prepare the HTTP headers accordingly.
  #
  # @param [Hash]         params      Default: @params.
  # @param [Hash]         headers     Default: {}.
  # @param [String, Hash] body        Default: *nil* unless `#update_request?`
  #
  # @return [Array<(String,Hash)>]    Message body plus headers for GET.
  # @return [Array<(Hash,Hash)>]      Query plus headers for PUT, POST, PATCH.
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
    # noinspection RubyNilAnalysis
    if body
      body = body.is_a?(Array) ? body.map { |v| api_body(v) } : api_body(body)
      body = body.to_json
      headers = headers.merge('Content-Type' => 'application/json')
    end
    return params, headers, body
  end

  # Process a message body component into a form ready for conversion to JSON.
  #
  # @param [String, Hash, *] obj
  #
  # @return [Hash{String=>*}]
  #
  def api_body(obj)
    obj = obj.as_json unless obj.is_a?(String)
    obj = reject_blanks(obj) if obj.is_a?(Hash)
    obj
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
    retry_opt = conn_opt.delete(:retry)

    Faraday.new(conn_opt) do |bld|
      bld.use           :instrumentation
      bld.use           :api_caching_middleware if CACHING
      bld.authorization :Bearer, access_token   if access_token.present?
      bld.request       :retry,  retry_opt
      bld.response      :logger, Log.logger
      bld.response      :raise_error
      bld.adapter       options[:adapter] || Faraday.default_adapter
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
  # === Bookshare API status codes
  # 301 Moved Permanently
  # 302 Found (typically, redirect to download location)
  # 200 OK
  # 201 Created
  # 202 Accepted
  # 400 Bad Request
  # 401 Unauthorized
  # 403 Forbidden
  # 404 Not Found
  # 405 Method Not Allowed
  # 406 Not Acceptable
  # 409 Conflict
  # 415 Unsupported Media Type
  # 500 Internal Server Error
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_responseCodes
  #
  def transmit(verb, action, params, headers, **opt)
    response = connection.send(verb, action, params, headers)
    raise empty_response_error(response) if response.nil?
    case response.status
      when 202, 204
        # No response body expected.
        action = nil
      when 200..299
        result = response.body
        raise empty_response_error(response) if result.blank?
        raise html_response_error(response)  if result =~ /\A\s*</
        action = nil
      when 301, 303, 308
        action = response.headers['Location']
        raise redirect_error(response) if action.blank?
      when 302, 307
        action = response.headers['Location']
        raise redirect_error(response) if action.blank?
      else
        raise response_error(response)
    end
    unless action.nil? || opt[:no_redirect] || options[:no_redirect]
      redirection = opt[:redirection].to_i
      raise redirect_limit_error if redirection >= max_redirects
      opt[:redirection] = (redirection += 1)
      __debug_line(leader: '!!!') do
        [service_name] << "REDIRECT #{redirection} TO #{action.inspect}"
      end
      response = transmit(:get, action, params, headers, **opt)
    end
    response
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Extract API parameters from *opt*.
  #
  # @param [Symbol]  method
  # @param [Boolean] check_req        Check for missing required keys.
  # @param [Boolean] check_opt        Check for extra optional keys.
  # @param [Hash]    opt
  #
  # @raise [RuntimeError]             Errors and #RAISE_ON_INVALID_PARAMS true.
  #
  # @return [Hash]                    Just the API parameters from *opt*.
  #
  def get_parameters(method, check_req: true, check_opt: false, **opt)
    properties     = api_methods(method)
    errors         = properties ? [] : ['unregistered API method']
    properties   ||= {}
    multi          = Array.wrap(properties[:multi])
    required_keys  = required_parameters(method)
    optional_keys  = optional_parameters(method)
    key_alias      = properties[:alias] || {}
    specified_keys = required_keys + optional_keys + key_alias.keys
    specified_keys += SERVICE_OPTIONS

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
    invalid_params(method, *errors) if errors.present?

    # Return with the options needed for the API request.
    # @type [Symbol] k
    # @type [*]      v
    opt.slice(*specified_keys).map { |k, v|
      k = key_alias[k] || k
      v = quote(v, separator: ' ') if v.is_a?(Array) && !multi.include?(k)
      k = encode_parameter(k)
      [k, v]
    }.to_h
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
  # @param [Hash] opt
  #
  # @return [Hash]                    A modified copy of *opt*.
  #
  def encode_parameters(**opt)
    encode_parameters!(opt)
  end

  # Preserve keys that would be mistaken for an ignored system parameter.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    The original *opt* now modified.
  #
  def encode_parameters!(opt)
    opt.transform_keys! { |k| encode_parameter(k) }
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
  # @param [Hash] opt
  #
  # @return [Hash]                    A modified copy of *opt*.
  #
  def decode_parameters(**opt)
    decode_parameters!(opt)
  end

  # Restore preserved keys.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    The original *opt* now modified.
  #
  def decode_parameters!(opt)
    opt.transform_keys! { |k| decode_parameter(k) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Report on errors in parameters supplied to an API method.
  #
  # @param [String, Symbol] method
  # @param [Array<String>]  errors
  # @param [Boolean]        no_raise
  #
  # @raise [RuntimeError]             Errors present and *no_raise* is *false*.
  #
  # @return [nil]                     No errors or *no_raise* is *true*.
  #
  def invalid_params(method, *errors, no_raise: !RAISE_ON_INVALID_PARAMS)
    return if errors.blank?
    errors.each { |problem| Log.warn("#{method}: #{problem}") }
    raise RuntimeError, ("#{method}: " + errors.join("\nAND ")) unless no_raise
  end

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  protected

  # A table of all error types and error subclass for the current service.
  #
  # @return [Hash{Symbol=>Class}]
  #
  # @see ApiService::Error::Method#error_subclass
  #
  def error_subclass
    @error_subclass ||= get_error_subclass
  end

  # Wrap an exception or response in a service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  #
  # @return [ApiService::Error]
  #
  def request_error(args = nil)
    error_subclass[:request].new(*args)
  end

  # Generate a authorization service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  # @return [ApiService::ConnectError]
  #
  def auth_error(args = nil)
    error_subclass[:auth].new(*args)
  end

  # Generate a bad data service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  # @return [ApiService::ConnectError]
  #
  def parse_error(args = nil)
    error_subclass[:parse].new(*args)
  end

  # Generate a connect service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  # @return [ApiService::ConnectError]
  #
  def connect_error(args = nil)
    error_subclass[:connect].new(*args)
  end

  # Generate a timeout service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  # @return [ApiService::TimeoutError]
  #
  def timeout_error(args = nil)
    error_subclass[:timeout].new(*args)
  end

  # Wrap an exception or response in a service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  #
  # @return [ApiService::Error]
  #
  def response_error(args = nil)
    error_subclass[:response].new(*args)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  # @return [ApiService::EmptyResultError]
  #
  def empty_response_error(args = nil)
    error_subclass[:empty_response].new(*args)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  # @return [ApiService::HtmlResultError]
  #
  def html_response_error(args = nil)
    error_subclass[:html_response].new(*args)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  # @return [ApiService::RedirectionError]
  #
  def redirect_error(args = nil)
    error_subclass[:redirection].new(*args)
  end

  # Generate a redirect limit service error.
  #
  # @param [Faraday::Response, Exception, String, Array, nil] args
  #
  # @return [ApiService::RedirectLimitError]
  #
  def redirect_limit_error(args = nil)
    error_subclass[:redirect_limit].new(*args)
  end

  # log_exception
  #
  # @param [Exception]              error
  # @param [Symbol, nil]            action
  # @param [Faraday::Response, nil] response
  # @param [Symbol, String, nil]    meth
  #
  # @return [void]
  #
  def log_exception(error, action: @action, response: @response, meth: nil)
    message = error.message.inspect
    __debug_line(leader: '!!!') do
      [service_name] << action.inspect << message << error.class
    end
    Log.log(error.is_a?(Api::Error) ? Log::WARN : Log::ERROR) do
      meth ||= 'request'
      status = %i[http_status status].find { |m| error.respond_to?(m) }
      status = status && error.send(status)&.inspect || '???'
      body   = response&.body
      log = ["#{service_name.upcase} #{meth}: #{message}"]
      log << "status #{status}"
      log << "body #{body}" if body.present?
      log.join('; ')
    end
  end

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  private

  # A table of all error types and error subclass for the given service.
  #
  # @param [ApiService, Class, String, nil] service   Default: `self.class`.
  #
  # @return [Hash{Symbol=>Class}]
  #
  # @see ApiService::Error::Method#error_subclass
  #
  #++
  # noinspection RubyNilAnalysis
  #--
  def get_error_subclass(service = nil)
    service ||= self.class
    service = service.class if service.is_a?(ApiService)
    service = service.name  if service.is_a?(Class)
    eval("::#{service}::Error.error_subclass")
  rescue => error
    Log.error("#{__method__}: #{error.class}: #{error.message}")
    return ApiService::Error.error_subclass
  end

end

__loading_end(__FILE__)
