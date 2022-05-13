# app/records/aws_s3/shared/transform_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting transformations of data fields.
#
module AwsS3::Shared::TransformMethods
  include Api::Shared::TransformMethods
  include AwsS3::Shared::CommonMethods
end

__loading_end(__FILE__)
