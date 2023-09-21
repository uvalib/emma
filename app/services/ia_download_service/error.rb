# app/services/ia_download_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic exception for IA download problems.
#
# === Usage Notes
# This is generally *not* the base class for exceptions in the
# IaDownloadService namespace:  Variants based on the error types defined under
# "emma.error.api" are derived from the related ApiService class; e.g.:
#
#   `IaDownloadService::AuthError < ApiService::AuthError`
#
# Only a distinct error type defined under "emma.error.ia_download" would
# derive from this class; e.g. if "emma.error.ia_download.unique" existed it
# would be defined as:
#
#   `IaDownloadService::UniqueError < IaDownloadService::Error`
#
# An exception in the IaDownloadService namespace can be identified by checking
# for `exception.is_a?(IaDownloadService::Error::ClassType)`.
#
class IaDownloadService::Error < ApiService::Error

  # Methods included in related error classes.
  #
  module ClassType

    include ApiService::Error::ClassType

    include HtmlHelper

    # =========================================================================
    # :section: Api::Error::Methods overrides
    # =========================================================================

    public

    # Name of the service and key into config/locales/error.en.yml.
    #
    # @return [Symbol]
    #
    def service
      :ia_download
    end

    # =========================================================================
    # :section: ExecError::Methods overrides
    # =========================================================================

    public

    # Get the message from within the response body of a Faraday exception.
    #
    # @param [Faraday::Response, Faraday::Error, Hash] src
    #
    # @return [Array<String>]
    # @return [Array<ActiveSupport::SafeBuffer>]  If note(s) were added.
    #
    def extract_message(src)
      result = []
      if (body = extract_body(src)).present?
        result << "#{service_name} response: #{body}" # TODO: I18n
        if (notes = added_messages(body)).present?
          result += notes
          result.map!.with_index do |line, count|
            html_opt = { class: 'line' }
            append_css!(html_opt, 'first') if count.zero?
            html_div(line, **html_opt)
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
  # :section: Error classes in this namespace
  # ===========================================================================

  generate_error_classes

end

# Non-functional hints for RubyMine type checking.
# noinspection LongLine
unless ONLY_FOR_DOCUMENTATION
  # :nocov:
  class IaDownloadService::AuthError          < ApiService::AuthError;          include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.auth'           || 'en.emma.error.api.auth'
  class IaDownloadService::CommError          < ApiService::CommError;          include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.comm'           || 'en.emma.error.api.comm'
  class IaDownloadService::SessionError       < ApiService::SessionError;       include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.session'        || 'en.emma.error.api.session'
  class IaDownloadService::ConnectError       < ApiService::ConnectError;       include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.connect'        || 'en.emma.error.api.connect'
  class IaDownloadService::TimeoutError       < ApiService::TimeoutError;       include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.timeout'        || 'en.emma.error.api.timeout'
  class IaDownloadService::XmitError          < ApiService::XmitError;          include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.xmit'           || 'en.emma.error.api.xmit'
  class IaDownloadService::RecvError          < ApiService::RecvError;          include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.recv'           || 'en.emma.error.api.recv'
  class IaDownloadService::ParseError         < ApiService::ParseError;         include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.parse'          || 'en.emma.error.api.parse'
  class IaDownloadService::RequestError       < ApiService::RequestError;       include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.request'        || 'en.emma.error.api.request'
  class IaDownloadService::NoInputError       < ApiService::NoInputError;       include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.no_input'       || 'en.emma.error.api.no_input'
  class IaDownloadService::ResponseError      < ApiService::ResponseError;      include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.response'       || 'en.emma.error.api.response'
  class IaDownloadService::EmptyResultError   < ApiService::EmptyResultError;   include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.empty_result'   || 'en.emma.error.api.empty_result'
  class IaDownloadService::HtmlResultError    < ApiService::HtmlResultError;    include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.html_result'    || 'en.emma.error.api.html_result'
  class IaDownloadService::RedirectionError   < ApiService::RedirectionError;   include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.redirection'    || 'en.emma.error.api.redirection'
  class IaDownloadService::RedirectLimitError < ApiService::RedirectLimitError; include IaDownloadService::Error::ClassType; end # 'en.emma.error.ia_download.redirect_limit' || 'en.emma.error.api.redirect_limit'
  # :nocov:
end

__loading_end(__FILE__)
