# app/records/aws_s3/shared/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to standard identifiers.
#
module AwsS3::Shared::IdentifierMethods
  include Api::Shared::IdentifierMethods
  include AwsS3::Shared::CommonMethods
end

__loading_end(__FILE__)
