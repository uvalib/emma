# app/services/concerns/api_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for external API service problems.
#
class ApiService::Error < Api::Error

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Array<Faraday::Response, Exception, Integer, String>] args
  #
  # This method overrides:
  # @see Api::Error#initialize
  #
  def initialize(*args)
    super(*append_error_description!(args))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Prefix seen in Bookshare error messages.
  #
  # @type [String]
  #
  ERROR_TAG = 'error_description'

  # If one of the arguments is a Faraday exception, use the error description
  # from its message body as the explicit message value in the arguments unless
  # they already include one.
  #
  # @param [Array] args
  #
  # @return [Array]                   The *args* array (possibly modified).
  #
  def append_error_description!(args)
    desc = args.none? { |arg| arg.is_a?(String) }
    desc &&= args.find { |arg| arg.is_a?(Faraday::Error) }
    desc &&= extract_message(desc)
    args += desc if desc.present?
    args
  end

  # Get the message from within the response body of a Faraday exception.
  #
  # @param [Faraday::Error] error
  #
  # @return [Array<String>]
  #
  def extract_message(error)
    body = error.response[:body].presence
    json = body && json_parse(body, symbolize_keys: false).presence || {}
    json = json.first       if json.is_a?(Array) && (json.size <= 1)
    return json.compact     if json.is_a?(Array)
    return Array.wrap(body) unless json.is_a?(Hash)
    desc = json[ERROR_TAG].presence
    desc ||=
      Array.wrap(json['messages']).map { |msg|
        msg = msg.to_s.strip
        if msg =~ /^[a-z0-9_]+=/i
          next unless msg.delete_prefix!("#{ERROR_TAG}=")
        end
        msg.remove(/\\"/)
      }.reject(&:blank?).presence
    desc ||= json.values.flat_map { |v| v if v.is_a?(Array) }.compact.presence
    Array.wrap(desc || body)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Methods to be included in subclasses.
  #
  module Methods

    # Initialize a new subclass instance.
    #
    # @param [Array<Faraday::Response, Exception, Integer, String>] args
    #
    # When included in the subclass this method overrides:
    # @see ApiService::Error#initialize
    #
    def initialize(*args)
      super(*append_default_message!(args))
    end

  end

end

# Exception raised to indicate that no (valid) inputs were provided so no
# service request was made.
#
class ApiService::NoInputError < ApiService::Error
  include ApiService::Error::Methods
end

# Exception raised to indicate that a valid message was received but it had no
# body or its body was empty.
#
class ApiService::EmptyResultError < ApiService::Error
  include ApiService::Error::Methods
end

# Exception raised to indicate that a message with an HTML body was received
# when HTML was not expected.
#
class ApiService::HtmlResultError < ApiService::Error
  include ApiService::Error::Methods
end

# Exception raised to indicate a invalid redirect destination.
#
# @see ApiService::Common#MAX_REDIRECTS
#
class ApiService::RedirectionError < ApiService::Error
  include ApiService::Error::Methods
end

__loading_end(__FILE__)
