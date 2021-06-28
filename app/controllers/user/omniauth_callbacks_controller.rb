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

  include SessionConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # OAuth2 providers recognized by this application.
  #
  # @type [Array<Symbol>]
  #
  PROVIDERS = %i[bookshare]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET  /users/auth/bookshare
  # == POST /users/auth/bookshare
  #
  # Initiate authentication with the remote service.
  #
  def passthru
    __debug_route
    __debug_request
    super
  end

  # == GET  /users/auth/bookshare/callback
  # == POST /users/auth/bookshare/callback
  #
  # Callback from the Bookshare auth service to finalize authentication.
  #
  # @see AuthConcern#set_auth_data
  #
  def bookshare
    __debug_route
    __debug_request
    set_auth_data(request)
    last_operation_update
    set_flash_message(:notice, :success, kind: 'Bookshare')
    sign_in_and_redirect(user)
  rescue => error
    auth_failure_redirect(message: error)
    re_raise_if_internal_exception(error)
  end

  # == GET /users/auth/bookshare/failure
  #
  # Called from OmniAuth::FailureEndpoint#redirect_to_failure and redirects to
  # Devise::OmniauthCallbacksController#after_omniauth_failure_path_for.
  #
  def failure
    __debug { "failure endpoint: request_format          = #{request_format.inspect}"}  # TODO: remove - testing
    __debug { "failure endpoint: is_navigational_format? = #{is_navigational_format?}"} # TODO: remove - testing
    __debug { "failure endpoint: is_flashing_format?     = #{is_flashing_format?}"}     # TODO: remove - testing
    __debug { "failure endpoint: failed_strategy         = #{failed_strategy.inspect}"} # TODO: remove?
    __debug { "failure endpoint: failure_message         = #{failure_message.inspect}"} # TODO: remove?
    __debug_route
    __debug_request
    set_flash_alert # TODO: remove? - testing
    super
  end

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
  def set_flash_alert(message = nil, kind = 'Bookshare')
    message ||= failure_message
    kind    ||= OmniAuth::Utils.camelize(failed_strategy.name)
    set_flash_message(:alert, :failure, kind: kind, reason: message)
  end

end

__loading_end(__FILE__)
