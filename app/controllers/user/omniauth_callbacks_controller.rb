# app/controllers/user/omniauth_callbacks_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# OAuth2 negotiation.
#
# @see AUTH_PROVIDERS
# @see https://github.com/plataformatec/devise#omniauth
#
class User::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  include SessionConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET  /users/auth/PROVIDER
  # == POST /users/auth/PROVIDER
  #
  # Initiate authentication with the remote service.
  #
  # _see #user_bookshare_omniauth_authorize_path  Route helper                  # if BS_AUTH
  # @see #user_shibboleth_omniauth_authorize_path Route helper
  #
  def passthru
    __log_activity
    __debug_route
    __debug_request
    super
  end
    .tap { |meth| disallow(meth) unless SHIBBOLETH || BS_AUTH }

  # == GET  /users/auth/bookshare/callback                                      # if BS_AUTH
  # == POST /users/auth/bookshare/callback
  #
  # Callback from the Bookshare auth service to finalize authentication.
  #
  # @see #user_bookshare_omniauth_callback_path   Route helper
  # @see AuthConcern#set_auth_data
  #
  def bookshare
    __log_activity
    __debug_route
    __debug_request
    self.resource = set_auth_data(request)
    last_operation_update
    set_flash_message(:notice, :success, kind: 'Bookshare')
    sign_in_and_redirect(resource)
  rescue => error
    auth_failure_redirect(message: error)
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # == GET  /users/auth/shibboleth/callback
  # == POST /users/auth/shibboleth/callback
  #
  # Callback from Shibboleth to finalize authentication.
  #
  # @see #user_shibboleth_omniauth_callback_path   Route helper
  # @see AuthConcern#set_auth_data
  #
  def shibboleth
    __log_activity
    __debug_route
    __debug_request
    self.resource = set_auth_data(request)
    last_operation_update
    set_flash_message(:notice, :success, kind: 'Shibboleth')
    sign_in_and_redirect(resource)
  rescue => error
    auth_failure_redirect(message: error)
  end
    .tap { |meth| disallow(meth) unless SHIBBOLETH }

  # == GET /users/auth/PROVIDER/failure
  #
  # Called from OmniAuth::FailureEndpoint#redirect_to_failure and redirects to
  # Devise::OmniauthCallbacksController#after_omniauth_failure_path_for.
  #
  def failure
    __log_activity
    __debug { "failure endpoint: request_format          = #{request_format.inspect}"  } # TODO: remove - testing
    __debug { "failure endpoint: is_navigational_format? = #{is_navigational_format?}" } # TODO: remove - testing
    __debug { "failure endpoint: is_flashing_format?     = #{is_flashing_format?}"     } # TODO: remove - testing
    __debug { "failure endpoint: failed_strategy         = #{failed_strategy.inspect}" } # TODO: remove?
    __debug { "failure endpoint: failure_message         = #{failure_message.inspect}" } # TODO: remove?
    __debug_route
    __debug_request
    set_flash_alert # TODO: remove? - testing
    super
  end
    .tap { |meth| disallow(meth) unless SHIBBOLETH || BS_AUTH }

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Display a flash error message.
  #
  # @param [String, nil] message
  # @param [String, nil] kind
  #
  # @return [void]
  #
  def set_flash_alert(message = nil, kind = nil)
    message ||= failure_message
    kind    ||= OmniAuth::Utils.camelize(failed_strategy.name)
    set_flash_message(:alert, :failure, kind: kind, reason: message)
  end

end

__loading_end(__FILE__)
