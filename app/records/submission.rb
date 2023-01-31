# app/records/submission.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects de-serialized from the SubmissionService.
#
# NOTE: This is a stub that may go away since SubmissionService doesn't
#   interface to an external API the way that other services do (and so doesn't
#   require the same kind of message serialization/de-serialization).
#
module Submission
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module Submission
  #include Submission::Api::Common
end

__loading_end(__FILE__)
