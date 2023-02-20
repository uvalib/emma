# app/services/ia_download_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IaDownloadService::Common
#
module IaDownloadService::Common

  include ApiService::Common

  include IaDownloadService::Properties

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # api_headers
  #
  # @param [Hash]         params      Default: @params.
  # @param [Hash]         headers     Default: {}.
  # @param [String, Hash] body        Default: *nil* unless `#update_request?`.
  #
  # @return [Array<(Hash,Hash,String)>] Message body plus headers for GET.
  # @return [Array<(Hash,Hash,Hash)>]   Query plus headers for PUT, POST, PATCH
  #
  def api_headers(params = nil, headers = nil, body = nil)
    super.tap do |_prms, hdrs, _body|
      auth   = hdrs.delete(:authorization) || IA_AUTH
      cookie = hdrs.delete(:cookie)        || IA_COOKIES
      hdrs['Authorization'] ||= auth
      hdrs['Cookie']        ||= cookie
    end
  end

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # Send an API request.
  #
  # @param [Symbol]            verb     Should always be :get.
  # @param [String]            action   Path to IA download.
  # @param [Hash, String, nil] params   Should always be blank.
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
  # == Usage Notes
  # Sets @response as a side-effect.
  #
  # == Implementation Notes
  # This will take several iterations, depending on the nature of the IA file.
  #
  # 1. If the file is unencrypted and the item is public-domain then the
  # original URL of the form "https:://archive.org/download/IDENT/IDENT.FORMAT"
  # will probably succeed.
  #
  # 2. Otherwise a redirect will occur to
  #
  #   "https://ia803005.us.archive.org/FORMAT/index.php?id=IDENT&dir=/00/items/IDENT&doc=IDENT&type=FORMAT"
  #
  # which will succeed if the unencrypted item can be generated "on-the-fly".
  #
  # 3. As a last-ditch fallback, the encrypted form of the original URL is
  # explicitly requested.
  #
  # NOTE: This method does not handle DAISY downloads from IA.
  # At this time IA does not support "on-the-fly" generation of unencrypted
  # DAISY.  The link to download encrypted DAISY is available without
  # authentication directly from the client browser.  In fact, attempting to
  # request it via this method has become problematic.
  #
  def transmit(verb, action, params, headers, **opt)
    pass = opt[:redirection].to_i
    dbg  = +"... #{__method__} | #{pass}"
    __debug_line(dbg) { { action: action, params: params, headers: headers } }

    @response = connection.send(verb, action, params, headers)
    raise empty_result_error if @response.nil?

    case @response.status

      when 200, 201, 203..299
        # If the requested file is directly available from S3 then we arrive
        # here in pass 1.  In later passes, the requested file will have been
        # generated on-the-fly by the IA server.
        result = @response.body
        __debug_line(dbg, 'GOOD') { "#{result&.size || 0} bytes" }
        raise empty_result_error(@response) if result.blank?
        raise html_result_error(@response)  if result =~ /\A\s*</
        action = nil

      when 301, 302, 303, 307, 308
        # If the requested file was not directly available, the redirect
        # should indicate the protected file if it exists.
        action    = @response['Location'] || :missing
        encrypted = action.match?(/_encrypted[_.]/)
        action    = action.remove('_encrypted') if encrypted
        __debug_line(dbg, 'REDIRECT') do
          parts = []
          parts << 'trying unencrypted first' if encrypted
          parts << "next = #{action.inspect}"
        end

      else
        # If the redirected URL failed there is still another possibility,
        # which is to request generation of an encrypted version of the file.
        # (The existence of this step was inferred by observing the behavior
        # of the "ia" Python script when executing "ia download".)  If the
        # URL that was requested already contains "_encrypted" then there are
        # no more things to try.
        if action.include?('&type=')
          action = action.sub(/(#{ext})$/, '_encrypted\1')
          __debug_line(dbg, 'ERROR', 'on-the-fly failed') { { next: action } }

        elsif !path.match?(/_encrypted[_.]/)
          action = action.sub(/(#{ext})$/, '_encrypted\1')
          __debug_line(dbg, 'ERROR', 'trying encrypted') { { next: action } }

        else
          __debug_line(dbg, 'FAIL', 'encrypted fallback failed')
          raise response_error(@response)
        end
    end

    if action.nil? || opt[:no_redirect] || options[:no_redirect]
      @response
    elsif action == :missing
      raise redirect_error(@response)
    elsif pass >= max_redirects
      raise redirect_limit_error
    else
      opt[:redirection] = (pass += 1)
      __debug_line(leader: '!!!') do
        [service_name] << "REDIRECT #{pass} TO #{action.inspect}"
      end
      transmit(:get, action, params, headers, **opt)
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
