# app/controllers/health_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HealthController
#
# == Usage Notes
# The endpoints implemented by this controller render only JSON and do not
# require authentication of the requester.
#
class HealthController < ApplicationController

  include HealthConcern
  include LogConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Not applicable.

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

=begin # TODO: This approach is not currently thread-safe.
  before_action :suppress_logger,   only: :check
  after_action  :unsuppress_logger, only: :check
=end

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
    logging = params[:logging]
    logging =
      if subsystems.blank?
        true?(logging)
      else
        logging.blank? || !false?(logging)
      end
    if logging
      check_action
    else
      Log.silence { check_action }
    end
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
    @subsystems ||= params[:subsystem].to_s.remove(/\s/).split(',')
  end

  # Acquire health status and render.
  #
  def check_action
    values   = get_health_status(*subsystems)
    response = HealthResponse.new(values)
    status   = response.failed? ? 500 : 200
    render json: response, status: status
  end

  # ===========================================================================
  # :section: LogConcern overrides
  # ===========================================================================

  protected

  # Excess logging is turned off for the standard all-subsystems health check
  # (which is hit frequently by automated processes) unless the URL parameter
  # 'logging=true' is included.
  #
  # If one or more comma-delimited subsystems is specified, full logging is
  # performed unless the URL parameter 'logging=false' is included.
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
