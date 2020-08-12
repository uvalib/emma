# app/controllers/concerns/ia_download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IaDownloadConcern
#
module IaDownloadConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'IaDownloadConcern')

    include RepositoryHelper

  end

  include ActionController::DataStreaming
  include SerializationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Base URL for Internet Archive downloads.
  #
  # @type [String]
  #
  IA_DOWNLOAD_BASE_URL = 'https://archive.org/download'

  # Maximum length of redirection chain.
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
  # === Implementation Notes
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

  # Redirect to a copy of a file downloaded from Internet Archive.
  #
  # @param [String] url
  # @param [Hash]   opt               Request headers,
  #
  # @return [void]
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
  # explicitly requested.  If the sequence gets to this stage, there may be a
  # problem with credentials (e.g., the )
  #
  def render_ia_download(url, **opt)
    url  = "#{IA_DOWNLOAD_BASE_URL}/#{url}" unless url.start_with?('http')
    base = File.basename(url)
    ext  = base.sub!(/^.*(_[^.]*\.zip)$/, '\1') || File.extname(url)
    path = url
    hdrs = { authorization: IA_AUTH, cookie: IA_COOKIES }.merge!(opt)
    data = nil
    pass = 0
    while (pass += 1) < IA_MAX_REDIRECTS
      dbg = +"... #{__method__} | #{pass}"
      __debug_line(dbg) { { path: path } }
      response =
        Faraday.get(path, nil, hdrs) do |req|
          # noinspection RubyResolve
          req.options.params_encoder = Faraday::IaParamsEncoder
        end
      dbg << " | status #{response.status.inspect}"
      __debug_line(dbg) { { headers: response.headers } }
      case response.status
        when 200, 201, 203..299
          # If the requested file is directly available from S3 then we arrive
          # here in pass 1.
          __debug_line(dbg, 'GOOD') { "#{response.body&.size || 0} bytes" }
          data = response.body
          raise ia_empty_response_error(response) if data.blank?
          raise ia_html_response_error(response)  if data =~ /\A\s*</
          type = response['Content-Type']
          disp = response['Content-Disposition']
          name = disp.to_s.sub(/^.*filename=([^;]+)(;.*)?$/, '\1').presence
          break # while

        when 301, 302, 303, 307, 308
          # If the requested file was not directly available, the redirect
          # should indicate the protected file if it exists.
          path = (response['Location'] if pass < IA_MAX_REDIRECTS)
          if path.blank?
            __debug_line(dbg, 'REDIRECT') { { next: response['Location'] } }
            raise ia_redirect_response_error(response)
          end
          encrypted  = path.match?(/_encrypted[_.]/)
          path = url = path.remove('_encrypted') if encrypted
          __debug_line(dbg, 'REDIRECT') do
            [].tap { |parts|
              parts << 'trying unencrypted first' if encrypted
              parts << "next = #{path.inspect}"
            }
          end

        else
          # If the redirected URL failed there is still another possibility,
          # which is to request generation of an encrypted version of the file.
          # (The existence of this step was inferred by observing the behavior
          # of the "ia" Python script when executing "ia download".)  If the
          # URL that was requested already contains "_encrypted" then there are
          # no more things to try.
          if path.include?('&type=')
            path = url = url.sub(/(#{ext})$/, '_encrypted\1')
            __debug_line(dbg, 'ERROR', 'on-the-fly failed') { { next: path } }

          elsif !path.match?(/_encrypted[_.]/)
            path = url = url.sub(/(#{ext})$/, '_encrypted\1')
            __debug_line(dbg, 'ERROR', 'trying encrypted') { { next: path } }

          else
            __debug_line(dbg, 'FAIL', 'encrypted fallback failed')
            raise ia_response_error(response)
          end
      end
    end

    type ||= 'application/octet-stream'
    name ||= File.basename(url)

    send_data(data, type: type, filename: name)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Wrap an exception or response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [ApiService::Error]
  #
  def ia_response_error(obj)
    ApiService::Error.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [ApiService::EmptyResultError]
  #
  def ia_empty_response_error(obj)
    ApiService::EmptyResultError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [ApiService::HtmlResultError]
  #
  def ia_html_response_error(obj)
    ApiService::HtmlResultError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [ApiService::RedirectionError]
  #
  def ia_redirect_response_error(obj)
    ApiService::RedirectionError.new(obj)
  end

end

__loading_end(__FILE__)
