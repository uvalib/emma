# app/controllers/health_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HealthController
#
class HealthController < ApplicationController

  include HealthConcern

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

  # == GET /healthcheck
  # == GET /health/check
  # == GET /health/check/:subsystem
  #
  def check
    values   = get_health_status(*params[:subsystem])
    response = HealthResponse.new(values)
    status   = response.degraded? ? 500 : 200
    render json: response, status: status
  end

end

__loading_end(__FILE__)
