# app/controllers/application_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# NOTE: The following is needed in order to induce loading to occur in a way
#   that all subclasses of EnumType have been loaded from configuration so that
#   their values can be used within the creation of constants in the helpers.

require 'search_service'

# Base class for all controllers.
#
class ApplicationController < ActionController::Base

  include Emma::TypeMethods
  include ParamsHelper

  include ConfigurationConcern
  include FlashConcern
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

  # ===========================================================================
  # :section: Session management
  # ===========================================================================

  # Handled individually by each controller subclass including SessionConcern.

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    __debug_exception('RESCUE_FROM', exception)
    flash_alert(config_text(:session, :expired))
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
