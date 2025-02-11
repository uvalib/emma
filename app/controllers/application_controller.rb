# app/controllers/application_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for all controllers.
#
class ApplicationController < ActionController::Base

  include Emma::TypeMethods
  include ParamsHelper

  include ConfigurationConcern
  include MetricsConcern
  include ResponseConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # Handled individually by each controller subclass.

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  check_authorization unless: :devise_controller?
  skip_authorization_check only: :return_to_sender

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  layout :current_layout

  protect_from_forgery with: :reset_session

  # Only allow modern browsers supporting webp images, web push, badges, import
  # maps, CSS nesting, and CSS :has.
  #allow_browser versions: :modern

  # ===========================================================================
  # :section: Session management
  # ===========================================================================

  # Handled individually by each controller subclass including SessionConcern.

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    # NOTE: This will normally be caught in SessionConcern#session_update.
    __debug_exception('ApplicationController RESCUE_FROM', exception)
    flash_alert(config_term(:session, :expired))
    redirect_to root_path
  end

  # ===========================================================================
  # :section: Helpers
  # ===========================================================================

  add_flash_types :error, :success # TODO: keep?

  helper_method :current_layout
  helper_method :modal?

  # ===========================================================================
  # :section: Helpers
  # ===========================================================================

  protected

  # The current layout template.
  #
  # @return [String]                  Basename of views/layouts/* template.
  # @return [FalseClass]              If this is an XHR request.
  #
  def current_layout
    if request_xhr?
      false
    elsif modal?
      'modal'
    else
      'application'
    end
  end

  # Indicate whether rendering within a modal dialog ('<iframe>').
  #
  def modal?
    @modal ||= true?(params[:modal])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # This is a catch-all for endpoints which are intentionally being rejected
  # with extreme prejudice.
  #
  def return_to_sender
    Log.silence(true)
    redirect_to "https://#{sender_ip}"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return the IP address of the requester.
  #
  # @param [ActionDispatch::Request, nil] req       Default: `request`.
  # @param [Array<String>, nil]           proxies   Trusted proxies.
  #
  # @return [String]
  #
  def sender_ip(req = nil, proxies = nil)
    req     ||= request
    proxies ||= ActionDispatch::RemoteIp::TRUSTED_PROXIES
    ActionDispatch::RemoteIp::GetIp.new(req, true, proxies).to_s
  end

end

__loading_end(__FILE__)
