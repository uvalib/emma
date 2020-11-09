# app/services/aws_s3_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'aws_s3'

# Deposit and retrieve records via AWS S3.
#
class AwsS3Service < ApiService

  include AwsS3

  # Include send/receive modules from "app/services/aws_s3_service/**.rb".
  include_submodules(self)

end

__loading_end(__FILE__)
