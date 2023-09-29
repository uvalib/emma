# app/records/aws_s3/message/removal_request.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A request to delete a prior submission to a partner repository.
#
# @note This capability is not currently supported by any partner repository.
#
class AwsS3::Message::RemovalRequest < AwsS3::Message::SubmissionRequest
  # TODO: Repository submission removal requests?
end

__loading_end(__FILE__)
