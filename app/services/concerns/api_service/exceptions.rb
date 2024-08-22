# app/services/concerns/api_service/exceptions.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiService::Exceptions
#
# @!attribute [r] exception
#   @return [ApiService::Error, nil]
#   The exception raised by the last #api access.
#
module ApiService::Exceptions

  include Emma::Common
  include Emma::Debug

  include ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The exception raised by the last #api access.
  #
  # @return [ApiService::Error, nil]
  #
  attr_reader :exception

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the latest API request generated an exception.
  #
  def error?
    @exception.present?
  end

  # Clear the latest API exception.
  #
  # (This can be done after an #api call to avoid generation of a flash
  # message.)
  #
  # @return [void]
  #
  def clear_error
    @exception = nil
  end

  # The message associated with the latest API exception.
  #
  # @return [ExecReport]
  # @return [nil]                     If there is no exception.
  #
  def exec_report
    ExecReport[@exception] if error?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Set the latest API error.
  #
  # @param [any, nil] error         Exception, Class<ApiService::Error>, Symbol
  # @param [Hash]     opt           Passed to initializer if *error* is a class
  #
  # @return [ApiService::Error]     New value of @exception.
  #
  def set_error(error, **opt)
    error = error_classes[error] if error.is_a?(Symbol)
    error = error.new(**opt)     if error.is_a?(Class)
    @exception =
      case error
        when nil, ApiService::Error     then error

        when Faraday::ConnectionFailed  then connect_error(error)
        when Down::ConnectionError      then connect_error(error)
        when Net::OpenTimeout           then connect_error(error)

        when Faraday::TimeoutError      then timeout_error(error)
        when Down::TimeoutError         then timeout_error(error)
        when Net::ReadTimeout           then timeout_error(error)
        when Net::WriteTimeout          then timeout_error(error)

        when Faraday::NilStatusError    then response_error(error)
        when Faraday::ServerError       then response_error(error)

        when Faraday::BadRequestError   then request_error(error)   # HTTP 400
        when Faraday::UnauthorizedError then auth_error(error)      # HTTP 401
        when Faraday::ForbiddenError    then auth_error(error)      # HTTP 403
        when Faraday::ResourceNotFound  then request_error(error)   # HTTP 404
        when Faraday::ProxyAuthError    then auth_error(error)      # HTTP 407
        when Faraday::ConflictError     then request_error(error)   # HTTP 409
        when Faraday::UnprocessableEntityError                      # HTTP 422
                                        then request_error(error)
        when Faraday::ClientError       then request_error(error)

        when Faraday::SSLError          then response_error(error)
        when Faraday::ParsingError      then parse_error(error)
        when Faraday::RetriableResponse then response_error(error)
        when Faraday::Error             then request_error(error)

        when Exception                  then response_error(error)
        else Log.warn { "#{__method__}: #{error.class} unexpected" }
      end
  end

  # A table of all error types and error classes for the current service.
  #
  # @return [Hash{Symbol=>Class}]
  #
  # @see ApiService::Error#error_classes
  #
  def error_classes
    @error_classes ||= get_error_classes
  end

  # ===========================================================================
  # :section: Transmission errors
  # ===========================================================================

  protected

  # Generate a service error indicating an authorization failure.
  #
  # @return [ApiService::AuthError]
  #
  def auth_error(...)
    error_classes[:auth].new(...)
  end

  # Generate a service error indicating a network communication failure.
  #
  # @return [ApiService::CommError]
  #
  def comm_error(...)
    error_classes[:comm].new(...)
  end

  # Generate a service error indicating a network session failure.
  #
  # @return [ApiService::SessionError]
  #
  def session_error(...)
    error_classes[:session].new(...)
  end

  # Generate a service error indicating a failure to make a network connection.
  #
  # @return [ApiService::ConnectError]
  #
  def connect_error(...)
    error_classes[:connect].new(...)
  end

  # Generate a service error indicating a network session timeout.
  #
  # @return [ApiService::TimeoutError]
  #
  def timeout_error(...)
    error_classes[:timeout].new(...)
  end

  # Generate a service error indicating a network send failure.
  #
  # @return [ApiService::XmitError]
  #
  def xmit_error(...)
    error_classes[:xmit].new(...)
  end

  # Generate a service error indicating a network receive failure.
  #
  # @return [ApiService::RecvError]
  #
  def recv_error(...)
    error_classes[:recv].new(...)
  end

  # Generate a service error indicating a bad network packet.
  #
  # @return [ApiService::ParseError]
  #
  def parse_error(...)
    error_classes[:parse].new(...)
  end

  # ===========================================================================
  # :section: Request errors
  # ===========================================================================

  protected

  # Generate a service error indicating the API request was invalid.
  #
  # @return [ApiService::RequestError]
  #
  def request_error(...)
    error_classes[:request].new(...)
  end

  # Generate a service error indicating the API request was empty.
  #
  # @return [ApiService::NoInputError]
  #
  def no_input_error(...)
    error_classes[:no_input].new(...)
  end

  # ===========================================================================
  # :section: Response errors
  # ===========================================================================

  protected

  # Wrap an exception or response in a service error.
  #
  # @return [ApiService::ResponseError]
  #
  def response_error(...)
    error_classes[:response].new(...)
  end

  # Generate a service error indicating that the response had no data.
  #
  # @return [ApiService::EmptyResultError]
  #
  def empty_result_error(...)
    error_classes[:empty_result].new(...)
  end

  # Generate a service error indicating HTML was received instead of JSON.
  #
  # @return [ApiService::HtmlResultError]
  #
  def html_result_error(...)
    error_classes[:html_result].new(...)
  end

  # Generate a service error indicating a failure to redirect.
  #
  # @return [ApiService::RedirectionError]
  #
  def redirect_error(...)
    error_classes[:redirection].new(...)
  end

  # Generate a service error indicating too many redirects.
  #
  # @return [ApiService::RedirectLimitError]
  #
  def redirect_limit_error(...)
    error_classes[:redirect_limit].new(...)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A table of all error types and error classes for the given service.
  #
  # @param [ApiService, Class, String, nil] service   Default: `self.class`.
  #
  # @return [Hash{Symbol=>Class}]
  #
  # @see ApiService::Error#error_classes
  #
  def get_error_classes(service = nil)
    service ||= self
    service   = service.class if service.is_a?(ApiService)
    service   = service.name  if service.is_a?(Class)
    eval("::#{service}::Error.error_classes")
  rescue => error
    Log.error("#{__method__}: #{error.class}: #{error.message}")
    return ApiService::Error.error_classes
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # log_exception
  #
  # @param [Exception]              error
  # @param [Symbol, nil]            action
  # @param [Faraday::Response, nil] response
  # @param [Symbol, String, nil]    meth
  #
  # @return [void]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def log_exception(error, action: @action, response: @response, meth: nil)
    response ||= error.try(:http_response) || error.try(:response)
    message    = error.try(:message).inspect
    level      = error.is_a?(ExecError) ? Log::WARN : Log::ERROR
    Log.log(level) do
      meth ||= :request
      stat   = ExecReport.http_status(error)
      stat ||= ExecReport.http_status(response)
      stat   = stat&.inspect       || '???'
      body   = response.try(:body) || response.try(:dig, :body)
      line   = ["#{service_name.upcase} #{meth}: #{message}"]
      line  << "status #{stat}"
      line  << "body #{body}" if body.present?
      line.join('; ')
    end
    __debug_line(leader: '!!!') do
      # noinspection RubyMismatchedArgumentType
      [service_name] << action.inspect << message << error.class
    end
  end

end

__loading_end(__FILE__)
