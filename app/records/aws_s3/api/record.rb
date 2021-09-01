# app/records/aws_s3/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects that are deposited into AWS S3.
#
class AwsS3::Api::Record < Api::Record

  include AwsS3::Api::Common
  include AwsS3::Api::Schema
  include AwsS3::Api::Record::Schema
  include AwsS3::Api::Record::Associations

end

__loading_end(__FILE__)
