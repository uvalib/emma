# app/services/ia_download_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Service implementation methods.
#
module IaDownloadService::Common

  include ApiService::Common

  include IaDownloadService::Properties

  include Emma::Common
  include Emma::Json

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # Include user identification.
  #
  # @param [Hash, nil] params         Default: @params.
  #
  # @return [Hash]                    New API parameters.
  #
  def api_options(params = nil)
    super.tap do |result|
      result[:requestor_name]  ||= user.full_name
      result[:requestor_email] ||= user.email_address
    end
  end

  # Include IA authorization headers.
  #
  # @param [Hash]         params      Default: @params.
  # @param [Hash]         headers     Default: {}.
  # @param [String, Hash] body        Default: *nil* unless `#update_request?`.
  #
  # @return [Array(Hash,Hash,String)] Message body plus headers for GET.
  # @return [Array(Hash,Hash,Hash)]   Query plus headers for PUT, POST, PATCH
  #
  def api_headers(params = nil, headers = nil, body = nil)
    super.tap do |_prms, hdrs, _body|
      hdrs.reverse_merge!(IA_HEADERS)
    end
  end

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # Send an Internet Archive "Printdisabled Unencrypted Ebook API" request.
  #
  # @param [Symbol]            verb     Should always be :get.
  # @param [String]            action   Path to IA download.
  # @param [Hash, String, nil] params
  # @param [Hash, nil]         headers
  # @param [Hash]              opt
  #
  # @option opt [Boolean]      :no_redirect
  # @option opt [Integer, nil] :redirection
  #
  # @raise [IaDownloadService::EmptyResultError]
  # @raise [IaDownloadService::HtmlResultError]
  # @raise [IaDownloadService::RedirectionError]
  # @raise [IaDownloadService::Error]
  #
  # @return [Faraday::Response]
  # @return [nil]
  #
  # === Usage Notes
  # Sets @response as a side effect.
  #
  def transmit(verb, action, params, headers, **opt)
    dbg, t1 = "... #{__method__}", Time.now
    elapsed = ->(t2 = Time.now) { '%.2f sec.' % (t2 - t1) }
    __debug_line(dbg) { { action: action, params: params, headers: headers } }

    redirect  = nil
    @response = connection.send(verb, action, params, headers)
    raise empty_result_error if @response.nil?

    case @response.status
      when 202
        # 202: "The file does not exist yet, but is being created."
        message = json_parse(@response.body)&.dig(:message) || 'Generating...'
        __debug_line(dbg, 'REQUESTED', elapsed.(), message)

      when 200..299
        # 200: "An ebook exists and is being served with this response."
        result = @response.body
        __debug_line(dbg, 'GOOD', elapsed.()) { "#{result&.size || 0} bytes" }
        raise empty_result_error(@response) if result.blank?
        raise html_result_error(@response)  if result =~ /\A\s*</

      when 301, 302, 303, 307, 308
        # NOTE: This is not currently a part of the API
        redirect = @response['Location'] || ''
        __debug_line(dbg, "REDIRECT #{redirect.inspect}", elapsed.())

      when 400...409
        # 400: "Invalid ebook type: XXX."
        # 400: "Required request params are missing or invalid."
        # 401: "The user must authorize to access the API."
        # 403: "The user is not allowed to access the API."
        __debug_line(dbg, 'CLIENT FAILURE', elapsed.()) do
          json_parse(@response.body)&.dig(:message) || 'unknown'
        end

      when 503
        # 503: "The service is temporarily unavailable."
        __debug_line(dbg, 'SERVICE UNAVAILABLE', elapsed.()) do
          json_parse(@response.body)&.dig(:message)
        end

      when 500..599
        __debug_line(dbg, 'SERVER FAILURE', elapsed.()) do
          json_parse(@response.body)&.dig(:message) || 'unknown'
        end

      else
        __debug_line(dbg, "UNEXPECTED STATUS #{@response.status}", elapsed.())
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

  private

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.include(IaDownloadService::Definition)
  end

end

__loading_end(__FILE__)
