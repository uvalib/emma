# app/services/submission_service/action/check.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SubmissionService::Action::Check
#
module SubmissionService::Action::Check

  include SubmissionService::Common
  include SubmissionService::Definition

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Receive a request to list associated jobs.
  #
  # @param [SubmissionService::ControlRequest, nil] request
  # @param [Manifest, String, nil]           manifest
  # @param [SubmitJob, String, nil]          job
  # @param [Hash]                            opt      To #post_flight
  #
  # @return [SubmissionService::StatusResponse]
  #
  #--
  # noinspection RailsParamDefResolve, RubyMismatchedReturnType
  #++
  def list_jobs(request = nil, manifest: nil, job: nil, **opt)
    self.request      = request ||= pre_flight(:list, manifest)
    self.start_time ||= request[:start_time]  || timestamp

    opt[:manifest_id] = request[:manifest_id] || manifest
    opt[:job_id]      = request[:job_id]      || job
    response          = SubmissionService::StatusResponse.new(**opt)

    self.end_time     = timestamp
    self.result       = post_flight(response)
  end

end

__loading_end(__FILE__)
