# app/records/aws_s3/shared/creator_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to authors, editors, etc.
#
module AwsS3::Shared::CreatorMethods
  include Api::Shared::CreatorMethods
  include AwsS3::Shared::CommonMethods
end

__loading_end(__FILE__)
