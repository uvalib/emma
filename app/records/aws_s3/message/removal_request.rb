# app/records/aws_s3/message/removal_request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A request to delete a prior submission to a member repository.
#
# @note Not currently supported by any member repository.
#
class AwsS3::Message::RemovalRequest < AwsS3::Message::SubmissionPackage
  # TODO: Repository submission removal requests?
end

__loading_end(__FILE__)
