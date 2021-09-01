# app/services/bookshare_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic exception for Bookshare API problems.
#
# == Usage Notes
# This is generally *not* the base class for exceptions in the BookshareService
# namespace:  Variants based on the error types defined under "emma.error.api"
# are derived from the related ApiService class; e.g.:
#
#   `BookshareService::AuthError < ApiService::AuthError`
#
# Only a distinct error type defined under "emma.error.bookshare" would derive
# from this class; e.g. "emma.error.bookshare.account" is defined as:
#
#   `BookshareService::AccountError < BookshareService::Error`
#
# An exception in the BookshareService namespace can be identified by checking
# for `exception.is_a?(BookshareService::Error::ClassType)`.
#
class BookshareService::Error < ApiService::Error

  # Methods included in related error classes.
  #
  module ClassType

    include ApiService::Error::ClassType

    # =========================================================================
    # :section: Api::Error::Methods overrides
    # =========================================================================

    public

    # Name of the service and key into config/locales/error.en.yml.
    #
    # @return [Symbol]
    #
    def service
      :bookshare
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
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
  class BookshareService::AuthError          < ApiService::AuthError;          include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.auth'           || 'en.emma.error.api.auth'
  class BookshareService::CommError          < ApiService::CommError;          include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.comm'           || 'en.emma.error.api.comm'
  class BookshareService::SessionError       < ApiService::SessionError;       include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.session'        || 'en.emma.error.api.session'
  class BookshareService::ConnectError       < ApiService::ConnectError;       include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.connect'        || 'en.emma.error.api.connect'
  class BookshareService::TimeoutError       < ApiService::TimeoutError;       include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.timeout'        || 'en.emma.error.api.timeout'
  class BookshareService::XmitError          < ApiService::XmitError;          include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.xmit'           || 'en.emma.error.api.xmit'
  class BookshareService::RecvError          < ApiService::RecvError;          include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.recv'           || 'en.emma.error.api.recv'
  class BookshareService::ParseError         < ApiService::ParseError;         include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.parse'          || 'en.emma.error.api.parse'
  class BookshareService::RequestError       < ApiService::RequestError;       include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.request'        || 'en.emma.error.api.request'
  class BookshareService::NoInputError       < ApiService::NoInputError;       include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.no_input'       || 'en.emma.error.api.no_input'
  class BookshareService::ResponseError      < ApiService::ResponseError;      include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.response'       || 'en.emma.error.api.response'
  class BookshareService::EmptyResultError   < ApiService::EmptyResultError;   include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.empty_result'   || 'en.emma.error.api.empty_result'
  class BookshareService::HtmlResultError    < ApiService::HtmlResultError;    include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.html_result'    || 'en.emma.error.api.html_result'
  class BookshareService::RedirectionError   < ApiService::RedirectionError;   include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.redirection'    || 'en.emma.error.api.redirection'
  class BookshareService::RedirectLimitError < ApiService::RedirectLimitError; include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.redirect_limit' || 'en.emma.error.api.redirect_limit'
  # === Unused exception classes:
  class BookshareService::AccountError       < BookshareService::Error;        include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.account'
  class BookshareService::SubscriptionError  < BookshareService::Error;        include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.subscription'
  class BookshareService::TitleError         < BookshareService::Error;        include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.title'
  class BookshareService::PeriodicalError    < BookshareService::Error;        include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.periodical'
  class BookshareService::ReadingListError   < BookshareService::Error;        include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.reading_list'
  class BookshareService::OrganizationError  < BookshareService::Error;        include BookshareService::Error::ClassType; end # 'en.emma.error.bookshare.organization'
  # :nocov:
end

__loading_end(__FILE__)
