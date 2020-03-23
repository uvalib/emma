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
    __debug_auth(log: true)
    __debug_request(log: true)
    super
  end

  # == GET  /users/auth/bookshare/callback
  # == POST /users/auth/bookshare/callback
  # Callback from the Bookshare auth service to finalize authentication.
  #
  def bookshare
    __debug_route
    auth_data = request.env['omniauth.auth']
    __debug_auth(log: true) { "env[omniauth.auth] = #{auth_data.inspect}" }
    __debug_request(log: true)
    user = User.from_omniauth(auth_data)
    if user.persisted?
      __debug_auth(log: true) { 'user persisted' }
      last_operation_update
      # sign_in_and_redirect(user, event: :authentication)
      sign_in_and_redirect(user)
      set_flash_message(:notice, :success, kind: 'Bookshare')
    else
      __debug_auth(log: true) { 'USER NOT PERSISTED' }
      # session['devise.bookshare_data'] = auth_data
      # redirect_to new_user_registration_url
      failure
    end
  end

  # ???
  #
  def failure
    __debug_route
    __debug_auth(log: true)
    __debug_request(log: true)
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

end

__loading_end(__FILE__)
