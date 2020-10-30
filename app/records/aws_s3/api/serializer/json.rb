# app/records/aws_s3/api/serializer/json.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process JSON data.
#
class AwsS3::Api::Serializer::Json < ::Api::Serializer::Json

  include AwsS3::Api::Serializer::Json::Schema
  include AwsS3::Api::Serializer::Json::Associations

end

__loading_end(__FILE__)
