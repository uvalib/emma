# app/services/search_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Common
#
module SearchService::Common

  include ApiService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, SearchService::Definition)
    base.send(:extend,  SearchService::Definition)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  BASE_URL    = 'https://virtserver.swaggerhub.com/kden/emma-federated-search-api' # TODO: SEARCH_BASE_URL
  API_VERSION = '0.0.1' # TODO: SEARCH_API_VERSION

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

    # Form the API path from the remaining arguments.
    args.unshift(API_VERSION) unless args.first == API_VERSION
    @action = args.join('/').strip
    @action = "/#{@action}" unless @action.start_with?('/')

    @action = "#{base_url}#{@action}" # TODO: ???

    # Determine whether the HTTP method indicates a write rather than a read
    # and prepare the HTTP headers accordingly then send the API request.
    @verb   = verb.to_s.downcase.to_sym
    update  = %i[put post patch].include?(@verb)
    params  = update ? @params.to_json : @params
    headers = ({ 'Content-Type' => 'application/json' } if update)
    __debug_line(leader: '>>>') {
      %w(search) << @action.inspect <<
        { params: params, headers: headers }.transform_values { |v|
          v.inspect if v.present?
        }.compact
    }
    @response = transmit(@verb, @action, params, headers, **opt)

  rescue Search::Error => error
    log_exception(method: method, error: error)

  rescue => error
    log_exception(method: method, error: error)
    error = SearchService::ResponseError.new(error)

  ensure
    __debug_line(leader: '<<<') {
      # noinspection RubyNilAnalysis
      resp   = error.respond_to?(:response) && error.response || @response
      status = resp.respond_to?(:status) && resp.status || resp&.dig(:status)
      data   = resp.respond_to?(:body) && resp.body || resp&.dig(:body)
      %w(search) << @action.inspect <<
        { status: status, data: data }.transform_values { |v|
          v.inspect.truncate(256)
        }
    }
    @response  = nil   if error
    @exception = error unless no_exception
    raise @exception   if @exception unless no_raise
    return @response
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
    __debug_line(leader: '!!!') {
      %w(search) << action.inspect << message << error.class
    }
    level  = error.is_a?(Search::Error) ? Logger::WARN : Logger::ERROR
    status = %i[http_status status].find { |m| error.respond_to?(m) }
    status = status ? error.send(status).inspect : '???'
    body   = response&.body
    Log.log(level) do
      log = ["SEARCH #{method}: #{message}"]
      log << "status #{status}"
      log << "body #{body}" if body.present?
      log.join('; ')
    end
  end

end

__loading_end(__FILE__)
