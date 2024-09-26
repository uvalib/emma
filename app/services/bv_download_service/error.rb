# app/services/bv_download_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic exception for BiblioVault collections download problems.
#
# === Usage Notes
# This is generally *not* the base class for exceptions in the
# BvDownloadService namespace:  Variants based on the error types defined under
# "en.emma.error.api" are derived from the related ApiService class; e.g.:
#
#   `BvDownloadService::AuthError < ApiService::AuthError`
#
# Only a distinct error type defined under "en.emma.error.bv_download" would
# derive from this class; e.g. if "en.emma.error.bv_download.unique" existed it
# would be defined as:
#
#   `BvDownloadService::UniqueError < BvDownloadService::Error`
#
# An exception in the BvDownloadService namespace can be identified by checking
# for `exception.is_a?(BvDownloadService::Error::ClassType)`.
#
class BvDownloadService::Error < ApiService::Error

  # Methods included in related error classes.
  #
  module ClassType

    include ApiService::Error::ClassType

    # =========================================================================
    # :section: Api::Error::Methods overrides
    # =========================================================================

    public

    # Name of the service and key into "config/locales/error.en.yml".
    #
    # @return [Symbol]
    #
    def service
      :bv_download
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
  class BvDownloadService::AuthError          < ApiService::AuthError;          include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.auth"           || "en.emma.error.api.auth"
  class BvDownloadService::CommError          < ApiService::CommError;          include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.comm"           || "en.emma.error.api.comm"
  class BvDownloadService::SessionError       < ApiService::SessionError;       include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.session"        || "en.emma.error.api.session"
  class BvDownloadService::ConnectError       < ApiService::ConnectError;       include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.connect"        || "en.emma.error.api.connect"
  class BvDownloadService::TimeoutError       < ApiService::TimeoutError;       include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.timeout"        || "en.emma.error.api.timeout"
  class BvDownloadService::XmitError          < ApiService::XmitError;          include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.xmit"           || "en.emma.error.api.xmit"
  class BvDownloadService::RecvError          < ApiService::RecvError;          include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.recv"           || "en.emma.error.api.recv"
  class BvDownloadService::ParseError         < ApiService::ParseError;         include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.parse"          || "en.emma.error.api.parse"
  class BvDownloadService::RequestError       < ApiService::RequestError;       include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.request"        || "en.emma.error.api.request"
  class BvDownloadService::NoInputError       < ApiService::NoInputError;       include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.no_input"       || "en.emma.error.api.no_input"
  class BvDownloadService::ResponseError      < ApiService::ResponseError;      include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.response"       || "en.emma.error.api.response"
  class BvDownloadService::EmptyResultError   < ApiService::EmptyResultError;   include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.empty_result"   || "en.emma.error.api.empty_result"
  class BvDownloadService::HtmlResultError    < ApiService::HtmlResultError;    include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.html_result"    || "en.emma.error.api.html_result"
  class BvDownloadService::RedirectionError   < ApiService::RedirectionError;   include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.redirection"    || "en.emma.error.api.redirection"
  class BvDownloadService::RedirectLimitError < ApiService::RedirectLimitError; include BvDownloadService::Error::ClassType; end # "en.emma.error.bv_download.redirect_limit" || "en.emma.error.api.redirect_limit"
  # :nocov:
end

__loading_end(__FILE__)
