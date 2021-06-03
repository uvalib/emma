# app/controllers/health_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle health-check requests.
#
# == Usage Notes
# The endpoints implemented by this controller render only JSON and do not
# require authentication of the requester.
#
class HealthController < ApplicationController

  include UserConcern
  include ParamsConcern
  include RunStateConcern
  include LogConcern
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
    render_version
  end

  # == GET /healthcheck[?logging=true]
  # == GET /health/check[?logging=true]
  # == GET /health/check/:subsystem[?logging=true]
  #
  def check
    logging = params[:logging]
    logging = subsystems.blank? ? true?(logging) : !false?(logging)
    if logging
      render_check
    else
      Log.silence { render_check }
    end
  end

  # == GET /health/run_state
  #
  def run_state
    @state = show_run_state
  end

  # == PUT /health/run_state
  #
  # == Usage Notes
  # Does nothing unless RunState::CLEARABLE or RunState::DYNAMIC.
  #
  def set_run_state
    __debug_route
    update_run_state
    redirect_to action: :run_state
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
    logging = subsystems.blank? ? true?(logging) : !false?(logging)
    super(logging)
  end

end

__loading_end(__FILE__)
