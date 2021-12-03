# app/records/aws_s3/api/serializer/hash.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for object-specific serializers that process data passed in as a
# Hash.
#
#--
# noinspection RubyResolve
#++
class AwsS3::Api::Serializer::Hash < Api::Serializer::Hash

  include AwsS3::Api::Serializer::Hash::Schema
  include AwsS3::Api::Serializer::Hash::Associations

end

__loading_end(__FILE__)
