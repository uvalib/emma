# app/services/lookup_service/_error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic exception for external lookup service API problems.
#
# === Usage Notes
# This is generally *not* the base class for exceptions in the LookupService
# namespace:  Variants based on the error types defined under
# "en.emma.error.api" are derived from the related ApiService class; e.g.:
#
#   `LookupService::AuthError < ApiService::AuthError`
#
# Only a distinct error type defined under "en.emma.error.lookup" would derive
# from this class; e.g. if "en.emma.error.lookup.unique" existed it would be
# defined as:
#
#   `LookupService::UniqueError < LookupService::Error`
#
# An exception in the LookupService namespace can be identified by checking for
# `exception.is_a?(LookupService::Error::ClassType)`.
#
class LookupService::Error < ApiService::Error

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
      :lookup
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
# :nocov:
# noinspection LongLine
unless ONLY_FOR_DOCUMENTATION
  class LookupService::AuthError          < ApiService::AuthError;          include LookupService::Error::ClassType; end # "en.emma.error.lookup.auth"            || "en.emma.error.api.auth"
  class LookupService::CommError          < ApiService::CommError;          include LookupService::Error::ClassType; end # "en.emma.error.lookup.comm"            || "en.emma.error.api.comm"
  class LookupService::SessionError       < ApiService::SessionError;       include LookupService::Error::ClassType; end # "en.emma.error.lookup.session"         || "en.emma.error.api.session"
  class LookupService::ConnectError       < ApiService::ConnectError;       include LookupService::Error::ClassType; end # "en.emma.error.lookup.connect"         || "en.emma.error.api.connect"
  class LookupService::TimeoutError       < ApiService::TimeoutError;       include LookupService::Error::ClassType; end # "en.emma.error.lookup.timeout"         || "en.emma.error.api.timeout"
  class LookupService::XmitError          < ApiService::XmitError;          include LookupService::Error::ClassType; end # "en.emma.error.lookup.xmit"            || "en.emma.error.api.xmit"
  class LookupService::RecvError          < ApiService::RecvError;          include LookupService::Error::ClassType; end # "en.emma.error.lookup.recv"            || "en.emma.error.api.recv"
  class LookupService::ParseError         < ApiService::ParseError;         include LookupService::Error::ClassType; end # "en.emma.error.lookup.parse"           || "en.emma.error.api.parse"
  class LookupService::RequestError       < ApiService::RequestError;       include LookupService::Error::ClassType; end # "en.emma.error.lookup.request"         || "en.emma.error.api.request"
  class LookupService::NoInputError       < ApiService::NoInputError;       include LookupService::Error::ClassType; end # "en.emma.error.lookup.no_input"        || "en.emma.error.api.no_input"
  class LookupService::ResponseError      < ApiService::ResponseError;      include LookupService::Error::ClassType; end # "en.emma.error.lookup.response"        || "en.emma.error.api.response"
  class LookupService::EmptyResultError   < ApiService::EmptyResultError;   include LookupService::Error::ClassType; end # "en.emma.error.lookup.empty_result"    || "en.emma.error.api.empty_result"
  class LookupService::HtmlResultError    < ApiService::HtmlResultError;    include LookupService::Error::ClassType; end # "en.emma.error.lookup.html_result"     || "en.emma.error.api.html_result"
  class LookupService::RedirectionError   < ApiService::RedirectionError;   include LookupService::Error::ClassType; end # "en.emma.error.lookup.redirection"     || "en.emma.error.api.redirection"
  class LookupService::RedirectLimitError < ApiService::RedirectLimitError; include LookupService::Error::ClassType; end # "en.emma.error.lookup.redirect_limit"  || "en.emma.error.api.redirect_limit"
end
# :nocov:

__loading_end(__FILE__)
