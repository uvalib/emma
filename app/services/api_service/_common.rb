# app/services/api_service/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/https'
require 'faraday'

# ApiService::Common
#
module ApiService::Common

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

  # Control whether information requests are ever cached. # TODO: ???
  #
  # @type [Boolean]
  #
  CACHING = false

  # Control whether validation errors cause a RuntimeError.
  #
  # @type [Boolean]
  #
  RAISE_ON_ERROR = Rails.env.test?

  # Original request parameters which should not be passed on to the API.
  #
  # @type [Array<Symbol>]
  #
  IGNORED_PARAMETERS = (ParamsHelper::IGNORED_PARAMETERS + %i[offset]).freeze

  # HTTP methods used by the API.
  #
  # @type [Array<Symbol>]
  #
  # == Usage Notes
  # Compare with AllowsType#values.
  #
  HTTP_METHODS =
    %w(GET PUT POST DELETE)
      .map { |w| [w.to_sym, w.downcase.to_sym] }.flatten.deep_freeze

  # @type [Hash{Symbol=>String}]
  API_RECV_MESSAGE = {
    default: 'Bad response from server',
  }.freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  API_RECV_RESPONSE = {
    default: nil
  }.freeze

  # @type [Hash{Symbol=>String}]
  API_SEND_MESSAGE = {
    default: 'Bad response from server',
  }.freeze

  # @type [Hash{Symbol=>(String,Regexp,nil)}]
  API_SEND_RESPONSE = {
    default: nil
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Interface to the shared data structure which holds the definition of the
  # API requests and parameters.
  #
  # noinspection RubyClassVariableUsageInspection
  module ApiRequests

    # Add a method name and its properties to #api_methods.
    #
    # @param [Hash{Symbol=>Hash}] prop
    #
    # @return [void]
    #
    # == Usage Notes
    # The definition of each API request method is followed by a block which
    # invokes this method in order to register the properties of the method and
    # its associated API endpoint.  The *prop* argument is expected to be a
    # hash with a single entry whose key is the symbol for the method and whose
    # value is a Hash containing the properties.
    #
    # All keys in the property hash are optional, however :reference_id must be
    # included for methods that map on to documented API requests.
    #
    # :alias          One or more identifiers which associate a method named
    #                 argument with the name of the API parameter it
    #                 represents.  (This is not needed for arguments with names
    #                 that are the same as the documented API parameter.)
    #
    # :required       One or more API parameters which are mandatory, which may
    #                 include either Path or Query parameters.
    #
    # :optional       One or more API optional Query parameters.
    #                 (Path parameters are never optional.)
    #
    # :multi          An array of one or more parameters that can be passed in
    #                 as a single value or as an array.
    #
    # :role           If given as :anonymous this is a hint that the request
    #                 should succeed even if the current user is not logged in.
    #
    # :reference_id   This is the HTML element ID of the request on the
    #                 Bookshare API documentation page.  If this is not
    #                 provided then the method is not treated as a true API
    #                 method.
    #
    # :topic          The base of the module in which the method was defined
    #                 added by this method as a hint for the API Explorer.
    #
    def add_api(prop)
      # __output { ". API Request method #{prop.keys.join(', ')}" }
      topic = self.to_s.demodulize
      prop = prop.transform_values { |v| v.merge(topic: topic) }
      (@@all_methods  ||= {}).merge!(prop)
      (@@true_methods ||= {}).merge!(prop.select { |_, v| v[:reference_id] })
    end

    # Properties for each method which implements an API request.
    #
    # By default only true (documented) API methods are returned, unless:
    # - If :synthetic is *true* then "fake" methods (which implement
    # functionality not directly supported by the API) are also included.
    # - If :synthetic is :only then only the "fake" methods are returned.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    # @overload api_methods(synthetic: false)
    #   @param [Boolean] synthetic
    #   @return [Hash{Symbol=>Hash}]
    #
    # @overload api_methods(method)
    #   @param [Symbol, String] method
    #   @return [Hash, nil]
    #
    def api_methods(method = nil, synthetic: false)
      @@all_methods  ||= {}
      @@true_methods ||= {}
      if method
        @@all_methods[method.to_sym]
      elsif synthetic == :only
        @@all_methods.except(*@@true_methods.keys)
      elsif synthetic
        @@all_methods
      else
        @@true_methods
      end
    end

    # The optional API query parameters for the given method.
    #
    # @param [Symbol, String] method
    #
    # @return [Array<Symbol>]
    #
    def optional_parameters(method)
      api_methods(method)&.dig(:optional)&.keys || []
    end

    # The required API query parameters for the given method.
    #
    # By default, these are only the Query or FormData parameters that would be
    # the required parameters that are to be passed through the method's
    # "**opt" options has.  If :all is *true*, the result will also include the
    # method's named parameters (translated to the name used in the
    # documentation [e.g., "userIdentifier" instead of "user"]).
    #
    # @param [Symbol, String] method
    # @param [Boolean]        all
    #
    # @return [Array<Symbol>]
    #
    def required_parameters(method, all: false)
      result = api_methods(method)&.dig(:required)&.keys || []
      result -= named_parameters(method) unless all
      result
    end

    # The subset of required API request parameters which are passed to the
    # implementation method via named parameters.
    #
    # By default, the names are translated to the documented parameter names.
    # If :no_alias is *true* then the actual parameter names are returned.
    #
    # @param [Symbol, String] method
    # @param [Boolean]        no_alias
    #
    # @return [Array<Symbol>]
    #
    def named_parameters(method, no_alias: false)
      alias_keys = !no_alias && api_methods(method)&.dig(:alias) || {}
      method(method).parameters.map { |pair|
        type, name = pair
        alias_keys[name] || name if %i[key keyreq].include?(type)
      }.compact
    end

  end

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  # @return [Array<Module>]           @see #include_submodules
  #
  def self.included(base)
    base.send(:include, ApiRequests)
    base.send(:extend,  ApiRequests)
  end

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

  # An exception raised by the last #api access.
  #
  # @return [Exception, nil]
  #
  attr_reader :exception

  # The user that invoked #api.
  #
  # @return [User, nil]
  #
  attr_reader :user

  # Last API request type.
  #
  # @return [String]
  #
  def request_type
    @verb.to_s.upcase
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

  # Most recently invoked HTTP request type.
  #
  # @param [Boolean, nil] api_key     If *true* include the :api_key parameter
  #                                     in the result.
  #
  # @return [String]
  #
  def latest_endpoint(api_key = false)
    params = (api_key ? @params : @params.except(:api_key)).presence
    params &&= params.to_param
    [@action, params].compact.join('?')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Set the user for the current session.
  #
  # @param [User] u
  #
  # @return [void]
  #
  def set_user(u)
    @user = (u if u.is_a?(User))
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
    result = @verb = @action = @response = @exception = nil
    headers = {}

    # Build API call parameters (minus local options).
    @params = opt.merge(api_key: API_KEY)
    @params.reject! { |k, _| IGNORED_PARAMETERS.include?(k) }
    @params.transform_keys! { |k| (k == :fmt) ? :format : k }
    @params[:limit] = MAX_LIMIT if @params[:limit].to_s == 'max'
    noexcp  = @params.delete(:no_exception)
    noraise = @params.delete(:no_raise) || noexcp
    params  = @params

    # Form the API path from the remaining arguments.
    args.unshift(API_VERSION) unless args.first == API_VERSION
    @action = args.join('/').strip
    @action = "/#{@action}" unless @action.start_with?('/')

    # Determine whether the HTTP method indicates a write rather than a read
    # and prepare the HTTP headers accordingly.
    @verb = verb.to_s.downcase.to_sym
    if %i[put post patch].include?(@verb)
      headers['Content-Type'] = 'application/json'
      params = params.to_json
    end

    # Invoke the API.
    __debug { ">>> #{__method__} | #{@action.inspect} | params = #{params.inspect} | headers = #{headers.inspect}" }
    @response = connection.send(@verb, @action, params, headers)
    body = @response&.body
    raise ApiService::EmptyResult.new(@response) unless body.present?
    raise ApiService::HtmlResult.new(@response)  if body.match?(/^\s*</)
    result = @response

  rescue SocketError, EOFError => error
    __debug { "!!! #{__method__} | #{@action.inspect} | #{error.message}" }
    @exception = error unless noexcp
    raise error        unless noraise # Handled by ApplicationController

  rescue ApiService::ResponseError => error
    __debug { "!!! #{__method__} | #{@action.inspect} | #{error.message}" }
    @exception = error unless noexcp

  rescue Faraday::ClientError => error
    __debug { "!!! #{__method__} | #{@action.inspect} | ERROR: #{error.message}" }
    unless noexcp
      resp = error.response
      json = MultiJson.load(resp[:body]) rescue nil
      desc = json&.dig('error_description')&.presence
      desc ||=
        Array.wrap(json&.dig('messages')).find { |msg|
          parts = msg.split(/=/)
          tag   = parts.shift
          next unless tag.include?('error_description')
          break parts.join('=').gsub(/\\"/, '').presence
        }
      error = Faraday::ClientError.new(desc, resp) if desc.present?
      @exception = error
    end

  rescue => error
    __debug { "!!! #{__method__} | #{@action.inspect} | ERROR: #{error.message}" }
    Log.error { "API #{__method__}: #{error.message}" }
    @exception = error unless noexcp

  ensure
    __debug { "<<< #{__method__} | #{@action.inspect} | status = #{@response&.status} | data = #{@response&.body.inspect.truncate(256)}" }
    @response = result
    return result

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
  #
  # @return [Faraday::Connection]
  #
  def make_connection(url = nil)
    conn_opts = {
      url:     (url || base_url),
      request: options.slice(:timeout, :open_timeout),
    }
    conn_opts[:request][:params_encoder] ||= Faraday::FlatParamsEncoder

    retry_opt = {
      max:                 options[:retry_after_limit],
      interval:            0.05,
      interval_randomness: 0.5,
      backoff_factor:      2,
    }

    # noinspection RubyYardReturnMatch
    Faraday.new(conn_opts) do |bld|
      bld.use           :instrumentation
      bld.use           :api_caching_middleware if CACHING
      bld.authorization :Bearer, access_token   if access_token.present?
      bld.request       :retry,  retry_opt
      bld.response      :logger, Log.logger
      bld.response      :raise_error
      bld.adapter       options[:adapter] || Faraday.default_adapter
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Extract the user name to be used for API parameters.
  #
  # @param [User, String] user
  #
  # @return [String]
  #
  def name_of(user)
    name = user.is_a?(Hash) ? user['uid'] : user
    name.to_s.presence || DEFAULT_USER
  end

  # Extract API parameters from *options*.
  #
  # @param [Symbol]  method
  # @param [Boolean] check_req        Check for missing required keys.
  # @param [Boolean] check_opt        Check for extra optional keys.
  # @param [Hash]    opt
  #
  # @return [Hash]                    Just the API parameters from *opt*.
  # @return [nil]                     If *method* is not an API method.
  #
  def get_parameters(method, check_req: true, check_opt: false, **opt)
    properties     = api_methods(method)
    return handle_errors(method, 'unregistered API method') if properties.nil?
    multi_valued   = Array.wrap(properties[:multi]).presence
    required_keys  = required_parameters(method)
    optional_keys  = optional_parameters(method)
    specified_keys = required_keys + optional_keys

    # Validate the keys provided.
    errors = []
    if check_req && (missing_keys = required_keys - opt.keys).present?
      error = +'missing API ' << 'parameter'.pluralize(missing_keys.size)
      errors.push(error << ' ' << missing_keys.join(', '))
    end
    if check_opt && (extra_keys = opt.keys - specified_keys).present?
      error = +'invalid API ' << 'parameter'.pluralize(extra_keys.size)
      errors.push(error << ' ' << extra_keys.join(', '))
    end
    handle_errors(method, *errors) if errors.present?

    # Return with the options needed for the API request.
    opt.slice(*specified_keys).map { |k, v|
      if !v.is_a?(Array)
        [k, v]
      elsif multi_valued&.include?(k)
        [k, v.map { |e| %Q("#{e}") }.join(' ')]
      else
        [k, v.join(', ')]
      end
    }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Report on errors.
  #
  # @param [String, Symbol] method
  # @param [Array<String>]  errors
  # @param [Boolean]        raise_on_error
  #
  # @raise [RuntimeError]             Iff *raise_on_error*.
  #
  # @return [nil]
  #
  def handle_errors(method, *errors, raise_on_error: RAISE_ON_ERROR)
    return if errors.blank?
    if raise_on_error
      raise RuntimeError, ("#{method}: " + errors.join("\nAND "))
    else
      errors.each { |problem| Log.warn("#{method}: #{problem}") }
    end
    nil
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # validate_response
  #
  # TODO: doesn't deal with all return codes
  #
  # @param [Faraday::Response, nil] response  Default: @response.
  #
  # @return [void]
  #
  def validate_response(response = @response)
    case response&.status
      when 200..299 then return if response&.body&.present?
      else               raise_exception(__method__)
    end
  end

  # raise_exception
  #
  # @param [Symbol, String] method  For log messages.
  #
  def raise_exception(method)
    response_table = API_SEND_RESPONSE
    message_table  = API_SEND_MESSAGE
    message = request_error_message(method, response_table, message_table)
    raise Api::Error, message
  end

  # Produce an error message from an HTTP response.
  #
  # @param [Symbol, String]         method          For log messages.
  # @param [Hash, nil]              response_table
  # @param [Hash, nil]              template_table
  # @param [Net::HTTPResponse, nil] response        Default: @response.
  #
  # @return [String]
  #
  def request_error_message(
    method          = nil,
    response_table  = nil,
    template_table  = nil,
    response        = @response
  )
    # Extract information from the HTTP response.
    body    = response&.body&.presence
    error   = body && Api::Error.new(body)
    code    = error&.code
    message = error&.message&.presence
    level   = message ? Logger::WARN : Logger::Error

    # Generate a message if one was not provided in the received data.
    message ||=
      if response.blank?
        'no HTTP result'
      elsif body.blank?
        'empty HTTP result body'
      else
        'unknown failure'
      end

    # Log the warning/error.
    Log.log(level) do
      log = ["API #{method}: #{message}"]
      log << "code #{code.inspect}"
      log << "body #{body}" if body.present?
      log.join('; ')
    end

    # Get the message template which matches *message*.
    template =
      if template_table.present?
        key =
          response_table&.find { |_, pattern|
            # noinspection RubyCaseWithoutElseBlockInspection
            case pattern
              when nil    then true
              when String then message.include?(pattern)
              when Regexp then message =~ pattern
            end
          }&.first
        template_table[key] || template_table[:default]
      end

    # Include the message from received data.
    if template.blank?
      message
    elsif template.include?('%')
      template % message
    else
      "#{template}: #{message}"
    end
  end

end

__loading_end(__FILE__)
