# app/controllers/user/omniauth_callbacks_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# OAuth2 negotiation.
#
# @see https://github.com/plataformatec/devise#omniauth
#
class User::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  PROVIDERS = %i[oauth2]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initiate OAuth2 authentication.
  #
  def oauth2
    __debug "User::OmniauthCallbacksController.#{__method__} | params #{params.inspect}"
    authentication_action
  end

  # == GET  /user/auth/oauth2
  # == POST /user/auth/oauth2
  # Initiate authentication with the remote service.
  #
  def passthru
    __debug "User::OmniauthCallbacksController.#{__method__} | params #{params.inspect}"
    super
  end

  # == GET  /user/auth/oauth2/callback
  # == POST /user/auth/oauth2/callback
  # Receive the authentication callback from the remote service.
  #
  def failure
    __debug "User::OmniauthCallbacksController.#{__method__} | params #{params.inspect}"
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The path used when OmniAuth fails.
  #
  # @param [?] scope
  #
  # @return [String]
  #
  def after_omniauth_failure_path_for(scope)
    super(scope)
  end

end

__loading_end(__FILE__)
