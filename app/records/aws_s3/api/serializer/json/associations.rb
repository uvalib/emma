# app/records/aws_s3/api/serializer/json/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides for JSON serializers.
#
# @see Api::Serializer::Json::Associations
#
module AwsS3::Api::Serializer::Json::Associations

  extend ActiveSupport::Concern

  include Api::Serializer::Json::Associations

  module ClassMethods
    include AwsS3::Api::Serializer::Json::Schema
    include Api::Serializer::Json::Associations::ClassMethods
  end

end

__loading_end(__FILE__)
