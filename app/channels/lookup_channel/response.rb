# app/channels/lookup_channel/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class LookupChannel::Response < ApplicationCable::Response

  # @see file://app/assets/javascripts/shared/lookup-response.js *TEMPLATE*
  TEMPLATE = {
    status:  nil,
    service: nil,           # Originating external lookup service.
    **superclass::TEMPLATE,
    discard: nil,           # List of late or erroneous jobs.
  }.freeze

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.template = TEMPLATE

  # ===========================================================================
  # :section: ApplicationCable::Response overrides
  # ===========================================================================

  public

  def self.data_url_base_path = 'tool/get_job_result'

end

class LookupChannel::LookupResponse < LookupChannel::Response
end

class LookupChannel::StatusResponse < LookupChannel::Response

  # ===========================================================================
  # :section: LookupChannel::Response overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [any, nil] values
  # @param [Hash]     opt
  #
  def initialize(values = nil, **opt)
    values = { service: values } unless values.nil? || values.is_a?(Hash)
    super
  end

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  protected

  def payload_normalize(value, except: nil)
    super.tap do |result|
      if (service = result.delete(:services) || result[:service])
        result[:service] = Array.wrap(service).map { |v| v.to_s.demodulize }
      end
    end
  end

end

class LookupChannel::InitialResponse < LookupChannel::StatusResponse

  # ===========================================================================
  # :section: ApplicationCable::Response::Payload overrides
  # ===========================================================================

  public

  def self.default_status = 'STARTING'

end

__loading_end(__FILE__)
