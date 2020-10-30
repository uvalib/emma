# app/records/aws_s3/api/serializer/xml.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process XML data.
#
class AwsS3::Api::Serializer::Xml < ::Api::Serializer::Xml

  include AwsS3::Api::Serializer::Xml::Schema
  include AwsS3::Api::Serializer::Xml::Associations

end

__loading_end(__FILE__)
