# app/services/submission_service/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for SubmissionService responses.
#
# @see SubmitChannel::Response
#
class SubmissionService::Response < ApplicationJob::Response

  include SubmissionService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEMPLATE = SubmitChannel::Response::TEMPLATE

  # ===========================================================================
  # :section: ApplicationJob::Response overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [SubmissionService::Response, Hash, Array, *] values
  # @param [Hash]                                        opt
  #
  def initialize(values = nil, **opt)
    if values.is_a?(Array)
      opt[:manifest_id] ||= extract_manifest_id(values.first)
      values = { data: values }
    elsif values.is_a?(SubmissionService::Request)
      values = { data: values.to_h }
    elsif values.is_a?(Hash) && !values.key?(:data)
      values = { data: values }
    end
    opt[:manifest_id] ||= extract_manifest_id(values, **opt)
    super
  end

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def self.batch? = false

  delegate :batch?, to: :class

end

# Response object for a submission request.
#
# @see SubmitChannel::SubmitResponse
# @see SubmitChannel::InitialResponse
# @see SubmitChannel::FinalResponse
# @see file:javascripts/shared/submit-response.js *SubmitResponse*
#
class SubmissionService::SubmitResponse < SubmissionService::Response

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEMPLATE = SubmitChannel::SubmitResponse::TEMPLATE

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template       = TEMPLATE
  def self.default_status = SubmitChannel::InitialResponse.default_status

end

# Response object for a submission request.
#
# @see SubmitChannel::StepResponse
# @see file:javascripts/shared/submit-response.js *SubmitStepResponse*
#
class SubmissionService::StepResponse < SubmissionService::SubmitResponse

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEMPLATE = SubmitChannel::StepResponse::TEMPLATE

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template       = TEMPLATE
  def self.default_status = SubmitChannel::StepResponse.default_status

end

# Response object for a submission request.
#
class SubmissionService::BatchSubmitResponse < SubmissionService::SubmitResponse

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.default_status = 'BATCHING'

  # ===========================================================================
  # :section: SubmissionService::Response overrides
  # ===========================================================================

  public

  def self.batch? = true

end

# Response object for a control request.
#
# @see SubmitChannel::ControlResponse
# @see file:javascripts/shared/submit-response.js *SubmitControlResponse*
#
class SubmissionService::ControlResponse < SubmissionService::Response

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEMPLATE = SubmitChannel::ControlResponse::TEMPLATE

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

end

# Response object for a list request.
#
# @see SubmitChannel::StatusResponse
# @see file:javascripts/shared/submit-response.js *SubmitStatusResponse*
#
class SubmissionService::StatusResponse < SubmissionService::Response

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEMPLATE = SubmitChannel::StatusResponse::TEMPLATE

  # ===========================================================================
  # :section: SubmissionService::Response overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [SubmissionService::StatusResponse, Hash, Array, *] values
  # @param [Hash]                                              opt
  #
  def initialize(values = nil, **opt)
    jobs = extract_hash!(opt, :job, :job_id).values.first
    opt[:manifest_id] ||= extract_manifest_id(values, **opt)
    if values.nil?
      jobs   = jobs ? Array.wrap(jobs) : jobs_for(opt[:manifest_id])
      values = jobs.map { |j| [(j.try(:active_job_id) || j), j] }.to_h
    end
    super
  end

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

end

__loading_end(__FILE__)
