# app/services/aws_s3_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Generic exception for AWS S3 API problems.
#
class AwsS3Service::Error < ApiService::Error

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
      :aws_s3
    end

  end

  include AwsS3Service::Error::Methods

  # ===========================================================================
  # :section: Error subclasses
  # ===========================================================================

  generate_error_subclasses

end

# Non-functional hints for RubyMine type checking.
# @private
# noinspection LongLine
# :nocov:
unless ONLY_FOR_DOCUMENTATION
  class AwsS3Service::AuthError          < ApiService::AuthError;          include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.auth'            || 'en.emma.error.api.auth'
  class AwsS3Service::CommError          < ApiService::CommError;          include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.comm'            || 'en.emma.error.api.comm'
  class AwsS3Service::SessionError       < ApiService::SessionError;       include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.session'         || 'en.emma.error.api.session'
  class AwsS3Service::ConnectError       < ApiService::ConnectError;       include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.connect'         || 'en.emma.error.api.connect'
  class AwsS3Service::TimeoutError       < ApiService::TimeoutError;       include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.timeout'         || 'en.emma.error.api.timeout'
  class AwsS3Service::XmitError          < ApiService::XmitError;          include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.xmit'            || 'en.emma.error.api.xmit'
  class AwsS3Service::RecvError          < ApiService::RecvError;          include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.recv'            || 'en.emma.error.api.recv'
  class AwsS3Service::ParseError         < ApiService::ParseError;         include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.parse'           || 'en.emma.error.api.parse'
  class AwsS3Service::RequestError       < ApiService::RequestError;       include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.request'         || 'en.emma.error.api.request'
  class AwsS3Service::NoInputError       < ApiService::NoInputError;       include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.no_input'        || 'en.emma.error.api.no_input'
  class AwsS3Service::ResponseError      < ApiService::ResponseError;      include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.response'        || 'en.emma.error.api.response'
  class AwsS3Service::EmptyResultError   < ApiService::EmptyResultError;   include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.empty_result'    || 'en.emma.error.api.empty_result'
  class AwsS3Service::HtmlResultError    < ApiService::HtmlResultError;    include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.html_result'     || 'en.emma.error.api.html_result'
  class AwsS3Service::RedirectionError   < ApiService::RedirectionError;   include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.redirection'     || 'en.emma.error.api.redirection'
  class AwsS3Service::RedirectLimitError < ApiService::RedirectLimitError; include AwsS3Service::Error::Methods; end # 'en.emma.error.aws_s3.redirect_limit'  || 'en.emma.error.api.redirect_limit'
end
# :nocov:

__loading_end(__FILE__)
