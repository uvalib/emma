# app/records/aws_s3/api/serializer/hash/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Hash-specific definition overrides for serialization.
#
# @see Api::Serializer::Hash::Schema
#
#--
# noinspection RubyResolve
#++
module AwsS3::Api::Serializer::Hash::Schema

  include AwsS3::Api::Serializer::Schema
  include Api::Serializer::Hash::Schema

end

__loading_end(__FILE__)
