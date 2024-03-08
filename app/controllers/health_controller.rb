# app/controllers/health_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle health-check requests.
#
# @see file:app/views/health/**
#
# === Usage Notes
# The endpoints implemented by this controller render only JSON and do not
# require authentication of the requester.
#
class HealthController < ApplicationController

  include ParamsConcern
  include RunStateConcern
  include HealthConcern

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

  after_action :no_cache, if: :request_get?

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /version
  # === GET /health/version
  #
  # @see #version_path                Route helper
  # @see #version_health_path         Route helper
  #
  def version
    render_version
  end

  # === GET /healthcheck[?logging=true]
  # === GET /health/check[?logging=true]
  # === GET /health/check/:subsystem[?logging=true]
  #
  # @see #healthcheck_path            Route helper
  # @see #check_health_path           Route helper
  # @see #check_subsystem_health_path Route helper
  # @see HealthConcern#render_check
  #
  def check
    logging = params[:logging]
    logging = subsystems.blank? ? true?(logging) : !false?(logging)
    Log.silence(true) unless logging
    render_check
  end

  # === GET /health/run_state
  #
  # @see #run_state_health_path       Route helper
  # @see #system_unavailable_path     Route helper
  # @see HealthConcern#show_run_state
  #
  def run_state
    @state = show_run_state
  end

  # === PUT /health/run_state
  #
  # @see #set_run_state_health_path   Route helper
  # @see HealthConcern#update_run_state
  #
  # === Usage Notes
  # Does nothing unless RunState::CLEARABLE or RunState::DYNAMIC.
  #
  def set_run_state
    __log_activity
    __debug_route
    update_run_state
    redirect_to action: :run_state
  end

end

__loading_end(__FILE__)
