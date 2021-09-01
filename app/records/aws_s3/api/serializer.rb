# app/records/aws_s3/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for serialization/de-serialization of objects derived from
# AwsS3::Api::Record.
#
class AwsS3::Api::Serializer < Api::Serializer

  include AwsS3::Api::Serializer::Schema
  include AwsS3::Api::Serializer::Associations

end

__loading_end(__FILE__)
