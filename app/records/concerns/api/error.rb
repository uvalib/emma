# app/records/concerns/api/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for API errors.
#
class Api::Error < RuntimeError

  include Emma::Json
  include ExplorerHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If applicable, the original exception that was rescued which resulted in
  # raising an Api::Error exception.
  #
  # @return [Exception, nil]
  #
  attr_reader :exception

  # If applicable, the HTTP response that resulted in the original exception.
  #
  # @return [Faraday::Response, nil]
  #
  attr_reader :response

  # If applicable, the HTTP status for the received message that resulted in
  # the original exception.
  #
  # @return [Integer, nil]
  #
  attr_reader :http_status

  # Initialize a new instance.
  #
  # @param [Array<Faraday::Response, Exception, Integer, String, true>] args
  #
  def initialize(*args)
    error_message = @http_status = @exception = @response = nil
    args.each do |arg|
      case arg
        when Faraday::Response then @response = arg
        when Exception         then @exception = arg
        when Integer           then @http_status = arg
        when String            then error_message = arg
        when true              then # Use default error message.
        when nil               then # Ignore nils silently.
        else Log.warn { "Api::Error#initialize: #{arg.inspect} ignored" }
      end
    end
    # noinspection RubyCaseWithoutElseBlockInspection
    case @exception
      when Api::Error
        error_message ||= @exception.message
        @http_status  ||= @exception.http_status
        @response     ||= @exception.response
        replace_exception(@exception.exception)
      when Faraday::Error
        error_message ||= @exception.message
        @http_status  ||= @exception.response&.dig(:status)
        replace_exception(@exception.wrapped_exception)
      when Exception
        error_message ||= @exception.message
        @http_status  ||= @response&.status
    end
    error_message ||= self.class.default_message
    super(error_message)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # replace_exception
  #
  # @param [Exception] e
  #
  # @return [Exception, nil]
  #
  def replace_exception(e)
    @exception = e if e.is_a?(Exception)
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # inspect
  #
  # @return [String]
  #
  # This method overrides
  # @see Object#inspect
  #
  def inspect
    items = {
      http_status: @http_status.inspect,
      response:    @response.inspect,
      exception:   api_format_result(@exception, html: false, indent: 2),
    }.map { |k, v| "@#{k}=#{v}" }.join(', ')
    '#<%s: %s %s>' % [self.class, self.message, items]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Force the default message (if it is defined) into the arguments unless they
  # already include an explicit message value.
  #
  # @param [Array] args
  #
  # @return [Array]                   The *args* array (possibly modified).
  #
  def append_default_message!(args)
    default = args.none? { |a| a.is_a?(String) }
    default &&= self.class.default_message(allow_nil: true).presence
    default ? (args << default) : args
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Default error message for the current instance based on the name of its
  # class.
  #
  # @param [Boolean] allow_nil
  # @param [Symbol]  source           Source repository
  #
  # @return [String]
  # @return [nil]                     If *allow_nil* is set to *true* and no
  #                                     default message is defined.
  #
  # @see en.emma.error.api in config/locales/en.yml
  #
  def self.default_message(allow_nil: false, source: nil)
    type = self.class.to_s
    source ||= type.sub(/::.*$/, '').underscore.presence
    type = type.demodulize.underscore.sub(/_?error$/, '').presence
    keys = []
    keys << :"emma.error.#{source}.#{type}"       if source && type
    keys << :"emma.error.api.#{type}"             if type
    keys << :"emma.error.#{source}.default"       if source
    keys << :'emma.error.api.default'
    keys << "#{type&.capitalize || 'API'} error"  unless allow_nil
    keys.uniq!
    I18n.t(keys.shift, default: keys)
  end

end

# =============================================================================
# :section: Authorization errors
# =============================================================================

public

# Base exception for Bookshare API authorization errors.
#
class Api::AuthError < Api::Error; end

# Base exception for Bookshare API communication errors.
#
class Api::CommError < Api::Error; end

# Base exception for Bookshare API session errors.
#
class Api::SessionError < Api::Error; end

# Exception raised to indicate that the session token has expired.
#
class Api::TimeoutError < Api::SessionError; end

# =============================================================================
# :section: Receive errors
# =============================================================================

public

# Base exception for Bookshare API receive errors.
#
class Api::RecvError < Api::CommError; end

# Exception raised to indicate a problem with received data.
#
class Api::ParseError < Api::RecvError; end

# =============================================================================
# :section: Transmit errors
# =============================================================================

public

# Base exception for Bookshare API transmit errors.
#
class Api::XmitError < Api::CommError; end

# Base exception for Bookshare API requests.
#
class Api::RequestError < Api::XmitError; end

__loading_end(__FILE__)
