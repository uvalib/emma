# app/services/submission_service/action/cancel.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SubmissionService::Action::Cancel
#
# @note The original approach for these methods is incompatible with the use of
#   GoodJob::Batch as the "waiter task".
#
module SubmissionService::Action::Cancel

  include SubmissionService::Common
  include SubmissionService::Definition

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  # Receive a request to stop a batch job.
  #
  # @param [SubmissionService::ControlRequest, nil] request
  # @param [Manifest, String]                manifest
  # @param [SubmitJob, String, nil]          job
  # @param [Hash]                            opt      To #post_flight
  #
  # @return [SubmissionService::ControlResponse] The value assigned to @result.
  #
  #--
  # noinspection RailsParamDefResolve, RubyMismatchedReturnType
  #++
  def batch_cancel(request = nil, manifest: nil, job: nil, **opt)
    self.request      = request ||= pre_flight(:stop, manifest)
    self.start_time ||= request[:start_time]  || timestamp

    opt[:command]     = :stop
    opt[:manifest_id] = request[:manifest_id] || manifest
    opt[:job_id]      = request[:job_id]      || waiter_job_id(manifest || job)
    # TODO: cancel indicated job
    # TODO: Bulk.find(manifest_id: manifest.id).update!(canceled: true)
    response          = SubmissionService::ControlResponse.new(**opt)

    self.end_time     = timestamp
    self.result       = post_flight(response)
  end
=end

end

__loading_end(__FILE__)
