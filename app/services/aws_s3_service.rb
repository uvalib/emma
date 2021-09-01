# app/services/aws_s3_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Deposit and retrieve records via AWS S3.
#
class AwsS3Service < ApiService

  include AwsS3

  # Include send/receive modules from "app/services/aws_s3_service/**.rb".
  include_submodules(self)

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
