# app/services/submission_service/action.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for API requests.
#
module SubmissionService::Action
  include SubmissionService::Action::Cancel
  include SubmissionService::Action::Control
  include SubmissionService::Action::Submit
end

__loading_end(__FILE__)
