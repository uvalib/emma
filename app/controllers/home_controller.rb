# app/controllers/home_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/home" pages.
#
# @see file:app/views/home/**
#
# === Usage Notes
# The endpoints implemented by this controller do not require authentication of
# the requester because the methods/views react according to the identity
# associated with the current session.
#
class HomeController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include HomeConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include AbstractController::Callbacks
  end
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!, only: %i[dashboard]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  respond_to :html
  respond_to :json, only: :dashboard

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /home
  #
  # The main application page.
  #
  # @see #root_path                   Route helper
  # @see #home_path                   Route helper
  #
  # === Implementation Notes
  # There is no app/views/home/main.html.erb; this method renders the user
  # dashboard for an authenticated session or the welcome screen otherwise.
  #
  def main
    if current_user
      redirect_to dashboard_path
    else
      redirect_to welcome_path
    end
  end

  # === GET /home/welcome
  #
  # The main application page for anonymous users.
  #
  # @see #welcome_path                Route helper
  #
  def welcome
    if LOG_SILENCER_WELCOME.any? { _1.include?(request.remote_ip) }
      Log.silence(true)
    else
      __log_activity
      __debug_route
    end
  end

  # === GET /home/dashboard
  #
  # The main application page for authenticated users.
  #
  # @see #dashboard_path              Route helper
  #
  def dashboard
    __log_activity
    __debug_route
    opt  = url_parameters
    fast = opt.key?(:fast) ? true?(opt[:fast]) : Rails.env.test?
    @details, @preferences, @history = get_account_details(fast: fast)
    response.status =
      case flash.now[:alert]
        when '', nil             then 200 # OK
        when /already signed in/ then 403 # Forbidden
        else                          401 # Unauthorized
      end
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values(nil, as: :array) }
    end
  end

end

__loading_end(__FILE__)
