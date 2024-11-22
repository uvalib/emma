# app/channels/submit_channel/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for SubmitJob responses.
#
class SubmitChannel::Response < ApplicationCable::Response

  # Allowed status values.
  #
  # @type [Hash{Symbol=>String}]
  #
  STATUS = {
    INITIAL:      'STARTING',
    STEP:         'STEP',
    INTERMEDIATE: 'DONE',
    FINAL:        'COMPLETE',
    ACK:          'ACK',
  }.freeze

  STATUS_INITIAL      = STATUS[:INITIAL]
  STATUS_STEP         = STATUS[:STEP]
  STATUS_INTERMEDIATE = STATUS[:INTERMEDIATE]
  STATUS_FINAL        = STATUS[:FINAL]
  STATUS_ACK          = STATUS[:ACK]

  TEMPLATE = {
    simulation:  nil,
    status:      nil,
    manifest_id: nil,
    **superclass::TEMPLATE,
  }.deep_freeze

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

  # ===========================================================================
  # :section: ApplicationCable::Response overrides
  # ===========================================================================

  public

  def self.data_url_base_path = 'manifest/get_job_result'

  # ===========================================================================
  # :section: ApplicationCable::Response overrides
  # ===========================================================================

  public

  def initialize(values = nil, **opt)
    super
    self[:simulation] = opt[:simulation]
  end

  # Indicate whether this response is part of a simulation.
  #
  # @note Currently unused.
  # :nocov:
  def simulation?
    self[:simulation].present?
  end
  # :nocov:

end

# The base class for SubmitJob responses indicating submission status.
#
class SubmitChannel::SubmitResponse < SubmitChannel::Response

  TEMPLATE = {
    **superclass::TEMPLATE,
    data: [],
  }.deep_freeze

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

end

# A response sent to indicate that the SubmitJob has started.
#
class SubmitChannel::InitialResponse < SubmitChannel::SubmitResponse

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.default_status = STATUS_INITIAL

end

# A response sent to when a SubmitJob submission step has completed.
#
class SubmitChannel::StepResponse < SubmitChannel::SubmitResponse

  TEMPLATE = {
    simulation: nil,
    status:     nil,
    step:       nil,
    **superclass::TEMPLATE,
    data: {
      count:     0,
      invalid:   [],
      submitted: [],
      success:   {},
      failure:   {},
    },
  }.deep_freeze

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.template       = TEMPLATE
  def self.default_status = STATUS_STEP

end

# A response sent to indicate that the SubmitJob has finished.
#
class SubmitChannel::FinalResponse < SubmitChannel::StepResponse

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.default_status = STATUS_FINAL

end

# A response sent to return feedback from a client-issued SubmitJob action.
#
# @note Currently unused.
# :nocov:
class SubmitChannel::ControlResponse < SubmitChannel::Response

  TEMPLATE = {
    simulation: nil,
    command:    nil,
    **superclass::TEMPLATE,
  }.deep_freeze

  # ===========================================================================
  # :section: ApplicationCable::Payload overrides
  # ===========================================================================

  public

  def self.template       = TEMPLATE
  def self.default_status = STATUS_ACK

  # ===========================================================================
  # :section: SubmitChannel::Response overrides
  # ===========================================================================

  public

  def initialize(values = nil, **opt)
    if values.is_a?(Symbol)
      super(nil, **opt, command: values)
    else
      super
    end
  end

end
# :nocov:

__loading_end(__FILE__)
