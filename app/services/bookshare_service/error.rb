# app/services/bookshare_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class BookshareService::Error < ApiService::Error

  # Methods to be included in related subclasses.
  #
  module Methods

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
      :bookshare
    end

  end

  include BookshareService::Error::Methods

  # ===========================================================================
  # :section: Error subclasses
  # ===========================================================================

  generate_error_subclasses

end

# Non-functional hints for RubyMine type checking.
# noinspection LongLine, DuplicatedCode
# :nocov:
unless ONLY_FOR_DOCUMENTATION
  class BookshareService::AuthError          < ApiService::AuthError;          include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.auth'           || 'en.emma.error.api.auth'
  class BookshareService::CommError          < ApiService::CommError;          include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.comm'           || 'en.emma.error.api.comm'
  class BookshareService::SessionError       < ApiService::SessionError;       include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.session'        || 'en.emma.error.api.session'
  class BookshareService::ConnectError       < ApiService::ConnectError;       include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.connect'        || 'en.emma.error.api.connect'
  class BookshareService::TimeoutError       < ApiService::TimeoutError;       include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.timeout'        || 'en.emma.error.api.timeout'
  class BookshareService::XmitError          < ApiService::XmitError;          include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.xmit'           || 'en.emma.error.api.xmit'
  class BookshareService::RecvError          < ApiService::RecvError;          include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.recv'           || 'en.emma.error.api.recv'
  class BookshareService::ParseError         < ApiService::ParseError;         include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.parse'          || 'en.emma.error.api.parse'
  class BookshareService::RequestError       < ApiService::RequestError;       include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.request'        || 'en.emma.error.api.request'
  class BookshareService::NoInputError       < ApiService::NoInputError;       include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.no_input'       || 'en.emma.error.api.no_input'
  class BookshareService::ResponseError      < ApiService::ResponseError;      include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.response'       || 'en.emma.error.api.response'
  class BookshareService::EmptyResultError   < ApiService::EmptyResultError;   include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.empty_result'   || 'en.emma.error.api.empty_result'
  class BookshareService::HtmlResultError    < ApiService::HtmlResultError;    include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.html_result'    || 'en.emma.error.api.html_result'
  class BookshareService::RedirectionError   < ApiService::RedirectionError;   include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.redirection'    || 'en.emma.error.api.redirection'
  class BookshareService::RedirectLimitError < ApiService::RedirectLimitError; include BookshareService::Error::Methods; end # 'en.emma.error.bookshare.redirect_limit' || 'en.emma.error.api.redirect_limit'
end
# :nocov:

__loading_end(__FILE__)
