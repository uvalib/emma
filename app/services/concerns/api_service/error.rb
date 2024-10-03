# app/services/concerns/api_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'nokogiri'

# Base exception for external API service problems.
#
class ApiService::Error < Api::Error

  # ===========================================================================
  # :section: Api::Error overrides
  # ===========================================================================

  public

  # Extract Faraday::Response messages.
  #
  # @param [Faraday::Response] arg
  #
  # @return [Array<String>]
  #
  # === Usage Notes
  # As a side-effect, if @http_response is nil it will be set here.
  #
  def faraday_response(arg)
    label  = "#{service_name} error"
    result = super.presence || [default_message]
    if result.many?
      ["#{label.pluralize}:", *result]
    else
      ["#{label}: #{result.first}"]
    end
  end

  # Enhance Faraday::Error messages.
  #
  # @param [Array<String>] messages
  #
  # @return [Array<String>]
  #
  def faraday_error(*messages)
    super.map do |m|
      m.sub(/^(.*)\s*(the server)\s*(.*)$/) do
        "The #{service_name} #{$3}:\n#{$1}"
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods included in related error classes.
  #
  module ClassType

    include Emma::Json

    include Api::Error::Methods

    # =========================================================================
    # :section: Api::Error::Methods overrides
    # =========================================================================

    public

    # The descriptive name of the current instance service.
    #
    # @return [String]
    #
    def service_name(...)
      @service_name ||= super
    end

    # =========================================================================
    # :section: ExecError::Methods overrides
    # =========================================================================

    public

    # Default error message for the current instance.
    #
    # @return [String]
    #
    def default_message
      @default_message ||= super || ''
    end

    # Prefix seen in Bookshare error messages and also in the header of OAuth2
    # responses.
    #
    # @type [String]
    #
    # @see https://datatracker.ietf.org/doc/html/rfc6750
    #
    ERROR_TAG = 'error_description'

    # Get the message from within the response body of a Faraday exception.
    #
    # @param [Faraday::Response, Faraday::Error, Hash] src
    #
    # @return [Array<String>]
    #
    def extract_message(src)
      # First check for an error description embedded in the response headers.
      # If not present then look at the response body.
      error_description = oauth2_error_header(src)

      # If there is no response body then prevent further analysis.
      body = extract_body(src)
      error_description ||= ([] unless body.present?)

      # Check for an HTML message, which may indicate that a web server is
      # responding with a 5xx error (rather than the application server).
      error_description ||=
        if body.start_with?('<')
          doc = Nokogiri.parse(body)
          doc = nil if doc.errors.present?
          extract_html(doc).presence || ''
        end

      # Check for a JSON message from the application server.
      error_description ||=
        if (data = json_parse(body, symbolize_keys: false, log: false))
          data = data.compact
          data = data.first if data.is_a?(Array) && !data.many?
          extract_json(data).presence
        end

      error_description ||= body

      # Note if this was an AWS-related error.
      if (aws_error = aws_error_header(src))
        err = error_description.presence
        aws = "AWS error #{aws_error.inspect}"
        aws = '(%s)' % aws if err
        err = err.first if err.is_a?(Array) && !err.many?
        s   = (' ' if err.is_a?(String) && !err.match?(/\s$/))
        error_description = err.is_a?(Array) ? [*err, aws] : "#{err}#{s}#{aws}"
      end

      Array.wrap(error_description)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Get the message headers from the source object.
    #
    # @param [Faraday::Response, Faraday::Error, Hash] src
    #
    # @return [Hash]
    #
    def extract_headers(src)
      # noinspection RailsParamDefResolve
      headers = src.try(:response_headers) || src.try(:headers) || src
      headers = (headers.presence if headers.is_a?(Hash))
      headers&.transform_keys { _1.to_s.downcase } || {}
    end

    # Get the message body from the source object.
    #
    # @param [Faraday::Response, Faraday::Error, Hash] src
    #
    # @return [String]
    #
    #--
    # noinspection RailsParamDefResolve
    #++
    def extract_body(src)
      body   = nil
      body ||= src.try(:response_body)
      body ||= src.try(:body)
      body ||= src.try(:response).try(:dig, :body)
      body ||= src.try(:dig, :body)
      to_utf8(body).to_s.strip
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Extract the OAuth2 error description from the response headers.
    #
    # @param [Faraday::Response, Faraday::Error, Hash] src
    #
    # @return [String, nil]
    #
    def oauth2_error_header(src)
      www_authenticate = extract_headers(src)['www-authenticate'].presence
      www_authenticate&.split(/\s*,\s*/)&.find do |part|
        k, v = part.split('=')
        next unless k == ERROR_TAG
        break v.to_s.sub(/^\s*(['"])\s*(.*)\s*\1\s*$/, '\2').presence
      end
    end

    # Extract an AWS error indication the response headers.
    #
    # @param [Faraday::Response, Faraday::Error, Hash] src
    #
    # @return [String, nil]
    #
    def aws_error_header(src)
      # noinspection SpellCheckingInspection
      extract_headers(src)['x-amzn-errortype'].presence
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Extract message(s) from a response body that has been determined to be
    # XML/HTML.
    #
    # @param [Nokogiri::HTML::Document, Nokogiri::XML::Document, nil] doc
    #
    # @return [Array<String>]
    #
    def extract_html(doc)
      Array.wrap(doc&.search('title', 'h1', 'body')&.first&.inner_text)
    end

    # Extract message(s) from a response body that has been determined to be
    # JSON.
    #
    # @param [any, nil] src           Hash
    #
    # @return [Array<String>]         If *src* was a Hash.
    # @return [Array<any>]            Otherwise.
    #
    def extract_json(src)
      result   = ([] if src.blank?)
      result ||= (src unless src.is_a?(Hash))
      result ||= src[ERROR_TAG].presence
      result ||=
        Array.wrap(src['messages']).map { |msg|
          msg = msg.to_s.strip
          if msg =~ /^[a-z0-9_]+=/i
            next unless msg.delete_prefix!("#{ERROR_TAG}=")
          end
          msg.remove(/\\"/)
        }.compact_blank.presence
      result ||= src['message'].presence
      result ||= src.values.flat_map { _1 if _1.is_a?(Array) }
      Array.wrap(result || src).compact
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include ClassType

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Produce a family of error subclasses based on the error types specified by
  # the union of "en.emma.error.api" and "en.emma.error.#{service}".
  #
  # For example, for `service` == :search, given type == :empty_result
  # this method will define
  #
  #   class SearchService::EmptyResultError < ApiService::EmptyResultError
  #     include SearchService::Error::ClassType
  #   end
  #
  # @return [Hash{Symbol=>Class}]     The value of @error_classes.
  #
  def self.generate_error_classes
    family_class      = self
    service_namespace = family_class.module_parent
    @error_classes =
      error_types.map { |type|
        error_class = "#{type}_error".camelize
        api_base    = ApiService.const_defined?(error_class, false)
        base_class  = api_base ? "ApiService::#{error_class}" : family_class
        service_namespace.module_eval <<~HERE_DOC
          class #{error_class} < #{base_class}
            include #{family_class}::ClassType
          end
        HERE_DOC
        [type, service_namespace.const_get(error_class)]
      }.to_h
  end

  # A table of error types mapped on to error classes in the namespace of the
  # related service.
  #
  # @return [Hash{Symbol=>Class}]
  #
  # @see ApiService::Error#generate_error_classes
  #
  def self.error_classes
    @error_classes ||= generate_error_classes
  end

  # ===========================================================================
  # :section: Error classes in this namespace
  # ===========================================================================

  generate_error_classes

end

# Non-functional hints for RubyMine type checking.
unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section: Transmission errors
  # ===========================================================================

  public

  # Exception raised to indicate that the user was not authorized to perform
  # the requested remote service action.
  #
  # @see "en.emma.error.api.auth"
  #
  class ApiService::AuthError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that there was a (transient) network error
  # when communicating with the remote service.
  #
  # @see "en.emma.error.api.comm"
  #
  class ApiService::CommError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that there was a session error in
  # communication with the remote service.
  #
  # @see "en.emma.error.api.session"
  #
  class ApiService::SessionError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that there was a problem establishing a
  # connection to the remote service.
  #
  # @see "en.emma.error.api.connect"
  #
  class ApiService::ConnectError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that the connection to the remote service
  # timed out.
  #
  # @see "en.emma.error.api.timeout"
  #
  class ApiService::TimeoutError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that there was network error while sending to
  # the remote service.
  #
  # @see "en.emma.error.api.xmit"
  #
  class ApiService::XmitError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that there was network error while receiving
  # from the remote service.
  #
  # @see "en.emma.error.api.recv"
  #
  class ApiService::RecvError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that the remote service returned malformed
  # network package data.
  #
  # @see "en.emma.error.api.parse"
  #
  class ApiService::ParseError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # ===========================================================================
  # :section: Request errors
  # ===========================================================================

  public

  # Exception raised to indicate a generic or unique issue with the request to
  # the external service API.
  #
  # @see "en.emma.error.api.request"
  #
  class ApiService::RequestError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that no (valid) inputs were provided so no
  # service request was made.
  #
  # @see "en.emma.error.api.no_input"
  #
  class ApiService::NoInputError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # ===========================================================================
  # :section: Response errors
  # ===========================================================================

  public

  # Exception raised to indicate a generic or unique issue with the response
  # from the external service API.
  #
  # @see "en.emma.error.api.response"
  #
  class ApiService::ResponseError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that a valid message was received but it had
  # no body or its body was empty.
  #
  # @see "en.emma.error.api.empty_result"
  #
  class ApiService::EmptyResultError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that a message with an HTML body was received
  # when HTML was not expected.
  #
  # @see "en.emma.error.api.html_result"
  #
  class ApiService::HtmlResultError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate a invalid redirect destination.
  #
  # @see "en.emma.error.api.redirection"
  #
  class ApiService::RedirectionError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # Exception raised to indicate that there were too many redirects.
  #
  # @see "en.emma.error.api.redirect_limit"
  #
  class ApiService::RedirectLimitError < ApiService::Error
    include ApiService::Error::ClassType
  end

  # :nocov:
end

__loading_end(__FILE__)
