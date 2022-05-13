# app/records/aws_s3/shared/date_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to dates.
#
module AwsS3::Shared::DateMethods
  include Api::Shared::DateMethods
  include AwsS3::Shared::CommonMethods
end

__loading_end(__FILE__)
