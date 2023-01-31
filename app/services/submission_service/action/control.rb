# app/services/submission_service/action/control.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SubmissionService::Action::Control
#
module SubmissionService::Action::Control

  include SubmissionService::Common
  include SubmissionService::Definition

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Receive a request to pause a batch job.
  #
  # @param [SubmissionService::ControlRequest, nil] request
  # @param [Manifest, String, nil]           manifest
  # @param [SubmitJob, String, nil]          job
  # @param [Hash]                            opt      To #post_flight
  #
  # @return [SubmissionService::ControlResponse] The value assigned to @result.
  #
  #--
  # noinspection RailsParamDefResolve, RubyMismatchedReturnType
  #++
  def batch_pause(request = nil, manifest: nil, job: nil, **opt)
    self.request      = request ||= pre_flight(:pause, manifest)
    self.start_time ||= request[:start_time]  || timestamp

    opt[:manifest_id] = request[:manifest_id] || manifest
    opt[:job_id]      = request[:job_id]      || waiter_job_id(manifest || job)
    # TODO: pause indicated job
    # TODO: Bulk.find(manifest_id: manifest.id).update!(paused: true)
    response          = SubmissionService::ControlResponse.new(**opt, command: :pause)

    self.end_time     = timestamp
    self.result       = post_flight(response)
  end

  # Receive a request to resume a paused batch job.
  #
  # @param [SubmissionService::ControlRequest, nil] request
  # @param [Manifest, String, nil]           manifest
  # @param [SubmitJob, String, nil]          job
  # @param [Hash]                            opt      To #post_flight
  #
  # @return [SubmissionService::ControlResponse] The value assigned to @result.
  #
  #--
  # noinspection RailsParamDefResolve, RubyMismatchedReturnType
  #++
  def batch_resume(request = nil, manifest: nil, job: nil, **opt)
    self.request      = request ||= pre_flight(:resume, manifest)
    self.start_time ||= request[:start_time]  || timestamp

    opt[:manifest_id] = request[:manifest_id] || manifest
    opt[:job_id]      = request[:job_id]      || waiter_job_id(manifest || job)
    # TODO: resume indicated job
    # TODO: Bulk.find(manifest_id: manifest.id).update!(paused: false)
    response          = SubmissionService::ControlResponse.new(**opt, command: :resume)

    self.end_time     = timestamp
    self.result       = post_flight(response)
  end

end

__loading_end(__FILE__)
