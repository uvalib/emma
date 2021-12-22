# app/records/aws_s3/api/serializer/obj.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Ruby (hash) object representation.
#
class AwsS3::Api::Serializer::Obj < Api::Serializer::Obj

  include AwsS3::Api::Serializer::Obj::Schema
  include AwsS3::Api::Serializer::Obj::Associations

end

__loading_end(__FILE__)
