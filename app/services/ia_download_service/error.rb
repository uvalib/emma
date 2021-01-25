# app/services/ia_download_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class IaDownloadService::Error < ApiService::Error

  # Methods to be included in related classes.
  #
  module Methods

    def self.included(base)
      base.send(:extend, self)
    end

    include HtmlHelper

    # Non-functional hints for RubyMine type checking.
    # :nocov:
    include ApiService::Error::Methods unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # =========================================================================
    # :section: ApiService::Error::Methods overrides
    # =========================================================================

    public

    # Name of the service and key into config/locales/error.en.yml.
    #
    # @return [Symbol]
    #
    def service
      :ia_download
    end

    # Get the message from within the response body of a Faraday exception.
    #
    # @param [Faraday::Error] error
    #
    # @return [Array<String>]
    # @return [Array<ActiveSupport::SafeBuffer>]  If note(s) were added.
    #
    def extract_message(error)
      result = []
      if (body = error.response[:body]).present?
        result << "#{service_name} response: #{body}" # TODO: I18n
        if (notes = added_messages(body)).present?
          result += notes
          row = 0
          result.map! do |line|
            css = %w(line)
            css << 'first' if row.zero?
            row += 1
            html_div(line, class: css_classes(css))
          end
        end
      end
      result
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Patterns of IA error response text and added notes.
    #
    # @type [Hash{String,Regexp=>String}]
    #
    IA_MESSAGES = { # TODO: I18n
      /refresh this page/ =>
        'Close this browser tab and retry the original download link.'
    }.deep_freeze

    # Produce additional line(s) to be displayed in the flash message along
    # with the original error response from Internet Archive.
    #
    # @param [String] ia_message
    #
    # @return [Array<ActiveSupport::SafeBuffer>]
    #
    def added_messages(ia_message)
      IA_MESSAGES.map { |pattern, note|
        html_tag(:strong, "(#{note})") if ia_message.match?(pattern)
      }.compact
    end

  end

  include IaDownloadService::Error::Methods

  # ===========================================================================
  # :section: Error subclasses
  # ===========================================================================

  generate_error_subclasses

end

# Non-functional hints for RubyMine type checking.
# noinspection LongLine
# :nocov:
unless ONLY_FOR_DOCUMENTATION
  class IaDownloadService::AuthError          < ApiService::AuthError;          include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.auth'           || 'en.emma.error.api.auth'
  class IaDownloadService::CommError          < ApiService::CommError;          include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.comm'           || 'en.emma.error.api.comm'
  class IaDownloadService::SessionError       < ApiService::SessionError;       include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.session'        || 'en.emma.error.api.session'
  class IaDownloadService::ConnectError       < ApiService::ConnectError;       include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.connect'        || 'en.emma.error.api.connect'
  class IaDownloadService::TimeoutError       < ApiService::TimeoutError;       include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.timeout'        || 'en.emma.error.api.timeout'
  class IaDownloadService::XmitError          < ApiService::XmitError;          include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.xmit'           || 'en.emma.error.api.xmit'
  class IaDownloadService::RecvError          < ApiService::RecvError;          include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.recv'           || 'en.emma.error.api.recv'
  class IaDownloadService::ParseError         < ApiService::ParseError;         include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.parse'          || 'en.emma.error.api.parse'
  class IaDownloadService::RequestError       < ApiService::RequestError;       include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.request'        || 'en.emma.error.api.request'
  class IaDownloadService::NoInputError       < ApiService::NoInputError;       include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.no_input'       || 'en.emma.error.api.no_input'
  class IaDownloadService::ResponseError      < ApiService::ResponseError;      include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.response'       || 'en.emma.error.api.response'
  class IaDownloadService::EmptyResultError   < ApiService::EmptyResultError;   include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.empty_result'   || 'en.emma.error.api.empty_result'
  class IaDownloadService::HtmlResultError    < ApiService::HtmlResultError;    include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.html_result'    || 'en.emma.error.api.html_result'
  class IaDownloadService::RedirectionError   < ApiService::RedirectionError;   include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.redirection'    || 'en.emma.error.api.redirection'
  class IaDownloadService::RedirectLimitError < ApiService::RedirectLimitError; include IaDownloadService::Error::Methods; end # 'en.emma.error.ia_download.redirect_limit' || 'en.emma.error.api.redirect_limit'
end
# :nocov:

__loading_end(__FILE__)
