# app/channels/submit_channel/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SubmitChannel::Response < ApplicationCable::Response

  TEMPLATE = {
    status:      nil,
    manifest_id: nil,
    **superclass::TEMPLATE,
  }.deep_freeze

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

  # ===========================================================================
  # :section: ApplicationCable::Response overrides
  # ===========================================================================

  public

  def self.data_url_base_path = 'manifest/get_job_result'

end

class SubmitChannel::SubmitResponse < SubmitChannel::Response

  TEMPLATE = {
    **superclass::TEMPLATE,
    data: [],
  }.deep_freeze

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

end

class SubmitChannel::InitialResponse < SubmitChannel::SubmitResponse

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.default_status = 'STARTING'

end

class SubmitChannel::FinalResponse < SubmitChannel::SubmitResponse

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.default_status = 'COMPLETE'

end

class SubmitChannel::StepResponse < SubmitChannel::SubmitResponse

  TEMPLATE = {
    status: nil,
    step:   nil,
    **superclass::TEMPLATE,
    data: {
      count:     0,
      submitted: [],
      success:   [],
      failure:   {},
      invalid:   [],
    },
  }.deep_freeze

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

  def self.default_status = 'STEP'

end

class SubmitChannel::ControlResponse < SubmitChannel::Response

  TEMPLATE = {
    command: nil,
    **superclass::TEMPLATE,
  }.deep_freeze

  # ===========================================================================
  # :section: SubmitChannel::Response overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Symbol, *] status
  # @param [Hash]      opt
  #
  def initialize(status = nil, **opt)
    if status.is_a?(Symbol)
      super(nil, **opt, status: status)
    else
      super
    end
  end

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

end

class SubmitChannel::StatusResponse < SubmitChannel::Response

  TEMPLATE = {
    **superclass::TEMPLATE,
    data: {
      count:     nil,
      submitted: nil,
      success:   nil,
      failure:   nil,
      invalid:   nil,
    },
  }.deep_freeze

  # ===========================================================================
  # :section: SubmitChannel::Response overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [*]    values
  # @param [Hash] opt
  #
  def initialize(values = nil, **opt)
    #values = { service: values } unless values.nil? || values.is_a?(Hash)
    super
  end

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

end

__loading_end(__FILE__)
