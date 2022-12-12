# app/channels/lookup_channel/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class LookupChannel::Response < ApplicationCable::Response

  TEMPLATE =
    make_response_template {{
      status:  nil,
      service: nil,
      user:    nil,
      time:    nil,
      job_id:  nil,
      class:   nil,
      data:    nil,
    }}.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  def initialize(values = nil, **opt)
    super
  end

  # ===========================================================================
  # :section: ApplicationCable::Response overrides
  # ===========================================================================

  public

  def self.template
    TEMPLATE
  end

end

class LookupChannel::InitialResponse < LookupChannel::Response

  DEFAULT_STATUS = 'STARTING'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [*]    values
  # @param [Hash] opt
  #
  def initialize(values = nil, **opt)
    values = { service: values } unless values.nil? || values.is_a?(Hash)
    super(values, **opt)
    self[:status] ||= DEFAULT_STATUS
  end

  # ===========================================================================
  # :section: ApplicationCable::Response overrides
  # ===========================================================================

  protected

  def normalize(value)
    value     = super
    service   = value.delete(:services) || value[:service]
    service &&= Array.wrap(service).map { |v| v.to_s.demodulize }
    service ? value.merge!(service: service) : value
  end

  # ===========================================================================
  # :section: ApplicationCable::Response overrides
  # ===========================================================================

  public

  def self.default_status
    DEFAULT_STATUS
  end

end

class LookupChannel::LookupResponse < LookupChannel::Response

  TEMPLATE =
    make_response_template {{
      status:   nil,
      service:  nil,
      user:     nil,
      time:     nil,
      duration: nil,
      count:    nil,
      discard:  nil,
      job_id:   nil,
      class:    nil,
      data:     nil,
    }}.freeze

  # ===========================================================================
  # :section: ApplicationCable::Response overrides
  # ===========================================================================

  public

  def self.template
    TEMPLATE
  end

end

__loading_end(__FILE__)
