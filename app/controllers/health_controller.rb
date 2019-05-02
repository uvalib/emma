# app/controllers/health_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HealthController
#
class HealthController < ApplicationController

  include HealthConcern
  include ParamsConcern

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  public

  before_action :suppress_logger,   only: :check
  after_action  :unsuppress_logger, only: :check

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /version
  # == GET /health/version
  #
  def version
    render json: { version: BUILD_VERSION }, status: 200
  end

  # == GET /healthcheck[?logging=true]
  # == GET /health/check[?logging=true]
  # == GET /health/check/:subsystem[?logging=true]
  #
  def check
    values   = get_health_status(*subsystems)
    response = HealthResponse.new(values)
    status   = response.degraded? ? 500 : 200
    render json: response, status: status
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The value of `params[:subsystem]`, which may be one or more comma-separated
  # subsystem names.
  #
  # @return [Array<String>]
  #
  def subsystems
    @subsystems ||= params[:subsystem].to_s.gsub(/\s/, '').split(',')
  end

  # ===========================================================================
  # :section: ParamsConcern overrides
  # ===========================================================================

  protected

  # Excess logging is turned off for the standard all-subsystems health check
  # (which is hit frequently by automated processes) unless the URL parameter
  # 'logging=true' is included.
  #
  # If one or more comma-delimited subsystems is specified, full logging is
  # performed unless the URL parameter 'logging=false' is included.
  #
  # This method overrides:
  # @see ParamsConcern#suppress_logger
  #
  def suppress_logger
    logging = params[:logging]
    logging =
      if subsystems.blank?
        true?(logging)
      else
        logging.blank? || !false?(logging)
      end
    super(logging)
  end

end

__loading_end(__FILE__)
