# app/records/aws_s3/shared/response_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to message elements supporting error reporting.
#
module AwsS3::Shared::ResponseMethods
  include Api::Shared::ResponseMethods
  include AwsS3::Shared::CommonMethods
end

__loading_end(__FILE__)
