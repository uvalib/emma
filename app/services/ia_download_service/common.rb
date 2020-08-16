# app/services/ia_download_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IaDownloadService::Common
#
module IaDownloadService::Common

  include ApiService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, IaDownloadService::Definition)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Maximum length of redirection chain.
  #
  # In the case of IA downloads, this includes both redirections driven by the
  # HTTP redirects and variations attempted within #transmit in order to find
  # a suitable fall-back download format.
  #
  # @type [Integer]
  #
  IA_MAX_REDIRECTS = 10

  # Authorization header for IA download requests.
  #
  # @type [String]
  #
  # @see https://archive.org/services/docs/api/ias3.html#skip-request-signing
  # @see https://archive.org/account/s3.php
  #
  IA_AUTH = "LOW #{IA_ACCESS}:#{IA_SECRET}"

  # Cookies to be sent to the IA server.
  #
  # == Implementation Notes
  # These values were obtained from a desktop development VM after installing
  # the "ia" Python script and running "ia configure" with the Email address
  # "emmadso@bookshare.org".  This generates a configuration file ~/.ia which
  # contains an "[s3]" section with the S3 access key and secret, and a
  # "[cookies]" section which contains these values.
  #
  # @see https://archive.org/services/docs/api/internetarchive/quickstart.html#configuring
  #
  IA_COOKIES = {
    'logged-in-user': IA_USER_COOKIE,
    'logged-in-sig':  IA_SIG_COOKIE
  }.map { |name, parts|
    parts = parts.join('; ') if parts.is_a?(Array)
    "#{name}=#{parts}"
  }.join('; ')

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Validate the presence of these values required for the full interactive
  # instance of the application.
  required_env_vars(:IA_DOWNLOAD_BASE_URL)

  # The URL for the API connection.
  #
  # @return [String]
  #
  def base_url
    @base_url ||= IA_DOWNLOAD_BASE_URL
  end

  # An API key is not a part of request URLs.
  #
  # @return [nil]
  #
  # @see #IA_COOKIES
  #
  def api_key
    nil
  end

  # API version is not a part of request URLs.
  #
  # @return [nil]
  #
  def api_version
    nil
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Maximum length of redirection chain.
  #
  # @type [Integer]
  #
  # This method overrides:
  # @see ApiService::Common#max_redirects
  #
  def max_redirects
    IA_MAX_REDIRECTS
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # api_headers
  #
  # @param [Hash]         params      Default: @params.
  # @param [Hash]         headers     Default: {}.
  # @param [String, Hash] body        Default: *nil* unless `#update_request?`.
  #
  # @return [Array<(String,Hash)>]    Message body plus headers for GET.
  # @return [Array<(Hash,Hash)>]      Query plus headers for PUT, POST, PATCH.
  #
  # This method overrides:
  # @see ApiService::Common#api_headers
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
  # :section:
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
  # @raise [ApiService::EmptyResultError]
  # @raise [ApiService::HtmlResultError]
  # @raise [ApiService::RedirectionError]
  # @raise [ApiService::Error]
  #
  # @return [Faraday::Response]
  # @return [nil]
  #
  # This method overrides:
  # @see ApiService::Common#transmit
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

    response = connection.send(verb, action, params, headers)
    raise empty_response_error(response) if response.nil?
    case response.status

      when 200, 201, 203..299
        # If the requested file is directly available from S3 then we arrive
        # here in pass 1.  In later passes, the requested file will have been
        # generated on-the-fly by the IA server.
        __debug_line(dbg, 'GOOD') { "#{response.body&.size || 0} bytes" }
        raise empty_response_error(response) if response.body.blank?
        raise html_response_error(response)  if response.body =~ /\A\s*</
        action = nil

      when 301, 302, 303, 307, 308
        # If the requested file was not directly available, the redirect
        # should indicate the protected file if it exists.
        action    = response['Location']
        raise redirect_error(response) if action.blank?
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
          raise response_error(response)
        end
    end
    unless action.nil? || opt[:no_redirect] || options[:no_redirect]
      raise redirect_limit_error if pass >= max_redirects
      opt[:redirection] = (pass += 1)
      __debug_line(leader: '!!!') do
        [service_name] << "REDIRECT #{pass} TO #{action.inspect}"
      end
      response = transmit(:get, action, params, headers, **opt)
    end
    response
  end

end

__loading_end(__FILE__)
