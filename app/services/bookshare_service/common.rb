# app/services/bookshare_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Common
#
module BookshareService::Common

  include ApiService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, BookshareService::Definition)
    base.send(:extend,  BookshareService::Definition)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  API_KEY      = BOOKSHARE_API_KEY
  BASE_URL     = BOOKSHARE_BASE_URL
  API_VERSION  = BOOKSHARE_API_VERSION
  AUTH_URL     = BOOKSHARE_AUTH_URL
  DEFAULT_USER = 'anonymous' # For examples # TODO: ???

  # Validate the presence of these values required for the full interactive
  # instance of the application.
  if rails_application?
    Log.error('Missing BOOKSHARE_API_KEY')  unless API_KEY
    Log.error('Missing BOOKSHARE_BASE_URL') unless BASE_URL
    Log.error('Missing BOOKSHARE_AUTH_URL') unless AUTH_URL
  end

  # Maximum accepted value for a :limit parameter.
  #
  # @type [Integer]
  #
  # == Implementation Notes
  # Determined experimentally.
  #
  MAX_LIMIT = 100

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Most recently invoked HTTP request type.
  #
  # @param [Boolean, nil] complete    If *true* include the :api_key parameter
  #                                     in the result.
  #
  # @return [String]
  #
  # This method overrides:
  # @see ApiService#latest_endpoint
  #
  def latest_endpoint(complete = false)
    params = (complete ? @params : @params.except(:api_key)).presence&.to_param
    [@action, params].compact.join('?')
  end

  # API key.
  #
  # @return [String]
  #
  # This method overrides:
  # @see ApiService#api_key
  #
  def api_key
    API_KEY
  end

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  public

  # Extract the user name to be used for API parameters.
  #
  # @param [User, String] user
  #
  # @return [String]
  #
  # This method overrides:
  # @see ApiService#name_of
  #
  def name_of(user)
    name = user.is_a?(Hash) ? user['uid'] : user
    name.to_s.presence || DEFAULT_USER
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get data from the API and update @response.
  #
  # @param [Symbol, String]           verb  One of :get, :post, :put, :delete
  # @param [Array<String,ScalarType>] args  Path components of the API request.
  # @param [Hash]                     opt   API request parameters.
  #
  # args[0]   [String]  Path component.
  # ...
  # args[-2]  [String]  Path component.
  # args[-1]  [Hash]    URL parameters except for:
  #
  # @option args.last [Boolean] :no_raise       If *true*, set @exception but
  #                                             do not raise it.
  #
  # @option args.last [Boolean] :no_exception   If *true*, neither set
  #                                             @exception nor raise it.
  #
  # @return [Faraday::Response]
  #
  # noinspection RubyScope
  def api(verb, *args, **opt)
    error = @verb = @action = @response = @exception = nil

    # Set local options from parameters or service options.
    opt, @params = partition_options(opt, *SERVICE_OPTIONS)
    no_exception = opt[:no_exception] || options[:no_exception]
    no_raise     = opt[:no_raise]     || options[:no_raise] || no_exception
    method       = opt[:method]       || calling_method

    # Build API call parameters (minus local options).
    @params.reject! { |k, _| IGNORED_PARAMETERS.include?(k) }
    decode_parameters!(@params)
    @params[:limit]   = MAX_LIMIT if @params[:limit].to_s == 'max'
    @params[:api_key] = api_key

    # Form the API path from the remaining arguments.
    args.unshift(API_VERSION) unless args.first == API_VERSION
    @action = args.join('/').strip
    @action = "/#{@action}" unless @action.start_with?('/')

    # Determine whether the HTTP method indicates a write rather than a read
    # and prepare the HTTP headers accordingly then send the API request.
    @verb   = verb.to_s.downcase.to_sym
    update  = %i[put post patch].include?(@verb)
    params  = update ? @params.to_json : @params
    headers = ({ 'Content-Type' => 'application/json' } if update)
    __debug {
      ">>> bookshare | #{@action.inspect} | " +
        { params: params, headers: headers }
          .map { |k, v| "#{k} = #{v.inspect}" unless v.blank? }
          .compact.join(' | ')
    }
    @response = transmit(@verb, @action, params, headers, **opt)

  rescue Bs::Error => error
    log_exception(method: method, error: error)

  rescue => error
    log_exception(method: method, error: error)
    error = BookshareService::ResponseError.new(error)

  ensure
    __debug {
      # noinspection RubyNilAnalysis
      resp   = error.respond_to?(:response) && error.response || @response
      status = resp.respond_to?(:status) && resp.status || resp&.dig(:status)
      data   = resp.respond_to?(:body)   && resp.body   || resp&.dig(:body)
      "<<< bookshare | #{@action.inspect} | " +
        { status: status, data: data }
          .map { |k, v| "#{k} = #{v.inspect.truncate(256)}" }
          .compact.join(' | ')
    }
    @response  = nil   if error
    @exception = error unless no_exception
    raise @exception   if @exception unless no_raise
    return @response
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Send an API request.
  #
  # @param [Symbol]            verb
  # @param [String]            action
  # @param [Hash, String, nil] params
  # @param [Hash, nil]         headers
  # @param [Hash]              opt
  #
  # @raise [BookshareService::EmptyResultError]
  # @raise [BookshareService::HtmlResultError]
  # @raise [BookshareService::RedirectionError]
  # @raise [BookshareService::ResponseError]
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
  # Compare with:
  # @see ApiService::Common#transmit
  #
  # noinspection DuplicatedCode
  def transmit(verb, action, params = nil, headers = nil, **opt)
    resp = connection.send(verb, action, params, headers)
    raise BookshareService::EmptyResultError.new(resp) if resp.nil?
    redirection = no_redirect = nil
    case resp.status
      when 200..299
        result = resp.body
        raise BookshareService::EmptyResultError.new(resp) if result.blank?
        raise BookshareService::HtmlResultError.new(resp)  if result =~ /^\s*</
      when 301, 303, 308
        redirection = opt[:redirection].to_i
        no_redirect = (redirection >= MAX_REDIRECTS)
      when 302, 307
        redirection = opt[:redirection].to_i
        no_redirect = (redirection >= MAX_REDIRECTS)
        no_redirect ||=
          opt.key?(:no_redirect) ? opt[:no_redirect] : options[:no_redirect]
      else
        raise BookshareService::ResponseError.new(resp)
    end
    if redirection
      action = resp.headers['Location']
      raise BookshareService::RedirectionError.new(resp) if action.blank?
      unless no_redirect
        opt = opt.merge(redirection: (redirection += 1))
        __debug {
          "!!! bookshare | REDIRECT #{redirection} TO #{action.inspect}"
        }
        resp = transmit(:get, action, params, headers, **opt)
      end
    end
    resp
  end

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  protected

  # log_exception
  #
  # @param [Exception]         error
  # @param [Symbol]            action
  # @param [Faraday::Response] response
  # @param [Symbol, String]    method
  #
  # @return [void]
  #
  def log_exception(error:, action: @action, response: @response, method: nil)
    method ||= 'request'
    message = error.message.inspect
    __debug {
      "!!! bookshare | #{action.inspect} | #{message} | #{error.class}"
    }
    level  = error.is_a?(Bs::Error) ? Logger::WARN : Logger::ERROR
    status = %i[http_status status].find { |m| error.respond_to?(m) }
    status = status ? error.send(status).inspect : '???'
    body   = response&.body
    Log.log(level) do
      log = ["BOOKSHARE #{method}: #{message}"]
      log << "status #{status}"
      log << "body #{body}" if body.present?
      log.join('; ')
    end
  end

end

__loading_end(__FILE__)
