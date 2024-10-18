# app/services/aws_s3_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Deposit and retrieve records via AWS S3.
#
class AwsS3Service < ApiService

  DESTRUCTIVE_TESTING = false

  include AwsS3

  include AwsS3Service::Properties
  include AwsS3Service::Action
  include AwsS3Service::Common
  include AwsS3Service::Definition
  include AwsS3Service::Status
  include AwsS3Service::Testing

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION

    # @!method instance
    #   @return [AwsS3Service]
    # @!method update
    #   @return [AwsS3Service]
    class << self
    end

  end
  # :nocov:

end

__loading_end(__FILE__)
