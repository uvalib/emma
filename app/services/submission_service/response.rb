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
  # @param [any, nil] values          SubmissionService::Response, Hash, Array
  # @param [Hash]     opt
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
    opt[:simulation] = opt[:simulation]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this response is part of a simulation.
  #
  # @note Currently unused.
  # :nocov:
  def simulation?
    self[:simulation].present?
  end
  # :nocov:

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
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
# @see file:javascripts/shared/submit-response.js *SubmitResponse*
#
class SubmissionService::SubmitResponse < SubmissionService::Response

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEMPLATE = SubmitChannel::SubmitResponse::TEMPLATE

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

end

# Initial response object for a submission request.
#
# @see SubmitChannel::InitialResponse
# @see file:javascripts/shared/submit-response.js *SubmitInitialResponse*
#
class SubmissionService::InitialResponse < SubmissionService::SubmitResponse

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

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
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.template       = TEMPLATE
  def self.default_status = SubmitChannel::StepResponse.default_status

end

# Response object for a submission request.
#
# @see SubmitChannel::StepResponse
# @see file:javascripts/shared/submit-response.js *SubmitStepResponse*
#
class SubmissionService::BatchSubmitResponse < SubmissionService::SubmitResponse

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.default_status = 'WAITING'

  # ===========================================================================
  # :section: SubmissionService::Response overrides
  # ===========================================================================

  public

  def self.batch? = true

end

# Final response object for a submission request.
#
# @see SubmitChannel::FinalResponse
# @see file:javascripts/shared/submit-response.js *SubmitFinalResponse*
#
class SubmissionService::FinalResponse < SubmissionService::StepResponse

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.default_status = SubmitChannel::FinalResponse.default_status

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
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.template       = TEMPLATE
  def self.default_status = SubmitChannel::ControlResponse.default_status

end

__loading_end(__FILE__)
