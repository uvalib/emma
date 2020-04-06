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
  # Initiate authentication with the remote service.
  #
  def passthru
    __debug_route
    __debug_request
    super
  end

  # == GET  /users/auth/bookshare/callback
  # == POST /users/auth/bookshare/callback
  # Callback from the Bookshare auth service to finalize authentication.
  #
  def bookshare
    auth_data = request.env['omniauth.auth']
    __debug_route { "env[omniauth.auth] = #{auth_data.inspect}" }
    __debug_request
    user = User.from_omniauth(auth_data)
    if user.persisted?
      __debug_line { [__debug_route_label, 'user persisted'] }
      session['omniauth.auth'] = auth_data
      last_operation_update
      sign_in_and_redirect(user)
      set_flash_message(:notice, :success, kind: 'Bookshare')

    else
      __debug_line { [__debug_route_label, 'USER NOT PERSISTED'] }
      failure
    end
  end

  # == GET /users/auth/bookshare/failure
  # Called from OmniAuth::FailureEndpoint#redirect_to_failure and redirects to
  # Devise::OmniauthCallbacksController#after_omniauth_failure_path_for.
  #
  def failure
    __debug_route
    __debug_request
    #set_flash_alert # TODO: remove?
    super
  end

  # ===========================================================================
  # :section: Devise::OmniauthCallbacksController overrides
  # ===========================================================================

  protected

  # The path used when OmniAuth fails.
  #
  # @param [?] scope
  #
  # @return [String]
  #
  # This method overrides:
  # @see Devise::OmniauthCallbacksController#after_omniauth_failure_path_for
  #
  def after_omniauth_failure_path_for(scope) # TODO: ???
    super(scope)
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
