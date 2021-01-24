# app/services/search_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SearchService::Error < ApiService::Error

  # Methods to be included in related classes.
  #
  module Methods

    # @private
    def self.included(base)
      base.send(:extend, self)
    end

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
      :search
    end

  end

  include SearchService::Error::Methods

  # ===========================================================================
  # :section: Error subclasses
  # ===========================================================================

  generate_error_subclasses

end

# Non-functional hints for RubyMine type checking.
# noinspection LongLine
# :nocov:
unless ONLY_FOR_DOCUMENTATION
  class SearchService::AuthError          < ApiService::AuthError;          include SearchService::Error::Methods; end # 'en.emma.error.search.auth'            || 'en.emma.error.api.auth'
  class SearchService::CommError          < ApiService::CommError;          include SearchService::Error::Methods; end # 'en.emma.error.search.comm'            || 'en.emma.error.api.comm'
  class SearchService::SessionError       < ApiService::SessionError;       include SearchService::Error::Methods; end # 'en.emma.error.search.session'         || 'en.emma.error.api.session'
  class SearchService::ConnectError       < ApiService::ConnectError;       include SearchService::Error::Methods; end # 'en.emma.error.search.connect'         || 'en.emma.error.api.connect'
  class SearchService::TimeoutError       < ApiService::TimeoutError;       include SearchService::Error::Methods; end # 'en.emma.error.search.timeout'         || 'en.emma.error.api.timeout'
  class SearchService::XmitError          < ApiService::XmitError;          include SearchService::Error::Methods; end # 'en.emma.error.search.xmit'            || 'en.emma.error.api.xmit'
  class SearchService::RecvError          < ApiService::RecvError;          include SearchService::Error::Methods; end # 'en.emma.error.search.recv'            || 'en.emma.error.api.recv'
  class SearchService::ParseError         < ApiService::ParseError;         include SearchService::Error::Methods; end # 'en.emma.error.search.parse'           || 'en.emma.error.api.parse'
  class SearchService::RequestError       < ApiService::RequestError;       include SearchService::Error::Methods; end # 'en.emma.error.search.request'         || 'en.emma.error.api.request'
  class SearchService::NoInputError       < ApiService::NoInputError;       include SearchService::Error::Methods; end # 'en.emma.error.search.no_input'        || 'en.emma.error.api.no_input'
  class SearchService::ResponseError      < ApiService::ResponseError;      include SearchService::Error::Methods; end # 'en.emma.error.search.response'        || 'en.emma.error.api.response'
  class SearchService::EmptyResultError   < ApiService::EmptyResultError;   include SearchService::Error::Methods; end # 'en.emma.error.search.empty_result'    || 'en.emma.error.api.empty_result'
  class SearchService::HtmlResultError    < ApiService::HtmlResultError;    include SearchService::Error::Methods; end # 'en.emma.error.search.html_result'     || 'en.emma.error.api.html_result'
  class SearchService::RedirectionError   < ApiService::RedirectionError;   include SearchService::Error::Methods; end # 'en.emma.error.search.redirection'     || 'en.emma.error.api.redirection'
  class SearchService::RedirectLimitError < ApiService::RedirectLimitError; include SearchService::Error::Methods; end # 'en.emma.error.search.redirect_limit'  || 'en.emma.error.api.redirect_limit'
end
# :nocov:

__loading_end(__FILE__)
