# app/services/concerns/api_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for Bookshare API problems.
#
class ApiService::Error < Api::Error; end

# Base exception for problems with content received from the Bookshare API.
#
class ApiService::ResponseError < ApiService::Error

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

  # If one of the arguments is a Faraday exception, use the error description
  # from its message body as the explicit message value in the arguments unless
  # they already include one.
  #
  # @param [Array] args
  #
  # @return [Array]                   The *args* array (possibly modified).
  #
  def append_error_description!(args)
    desc = args.none? { |a| a.is_a?(String) }
    desc &&= args.find { |v| v.is_a?(Faraday::Error) }
    desc &&= extract_message(desc).presence
    desc ? (args << desc) : args
  end

  # Get the message from within the response body of a Faraday exception.
  #
  # @param [Faraday::Error] error
  #
  # @return [String]
  # @return [nil]
  #
  def extract_message(error)
    json = MultiJson.load(error.response[:body]) rescue nil
    return if json.blank?
    desc = json['error_description']
    return desc if desc.present?
    Array.wrap(json['messages']).find do |msg|
      parts = msg.split(/=/)
      tag   = parts.shift
      next unless tag.include?('error_description')
      return parts.join('=').gsub(/\\"/, '').presence
    end
  end

end

# Exception raised to indicate that a valid message was received but it had no
# body or its body was empty.
#
class ApiService::EmptyResultError < ApiService::ResponseError

  # Initialize a new instance.
  #
  # @param [Array<Faraday::Response, Exception, Integer, String>] args
  #
  # This method overrides:
  # @see ApiService::ResponseError#initialize
  #
  def initialize(*args)
    super(*append_default_message!(args))
  end

end

# Exception raised to indicate that a message with an HTML body was received
# when HTML was not expected.
#
class ApiService::HtmlResultError < ApiService::ResponseError

  # Initialize a new instance.
  #
  # @param [Array<Faraday::Response, Exception, Integer, String>] args
  #
  # This method overrides:
  # @see ApiService::ResponseError#initialize
  #
  def initialize(*args)
    super(*append_default_message!(args))
  end

end

# Exception raised to indicate a invalid redirect destination.
#
# @see ApiService::Common#MAX_REDIRECTS
#
class ApiService::RedirectionError < ApiService::ResponseError

  # Initialize a new instance.
  #
  # @param [Array<Faraday::Response, Exception, Integer, String>] args
  #
  # This method overrides:
  # @see ApiService::ResponseError#initialize
  #
  def initialize(*args)
    super(*append_default_message!(args))
  end

end

__loading_end(__FILE__)
