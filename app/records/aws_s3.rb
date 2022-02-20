# app/records/aws_s3.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects serialized into an AWS S3 bucket.
#
module AwsS3
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module AwsS3
  include AwsS3::Api::Common
end

__loading_end(__FILE__)
