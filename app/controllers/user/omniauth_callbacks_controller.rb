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

=begin
  PROVIDERS = %i[oauth2]
=end
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
    $stderr.puts "User::OmniauthCallbacksController.#{__method__} | #{request.method} | params #{params.inspect}"
    super
  end

=begin
  # == GET  /users/auth/oauth2/callback
  # == POST /users/auth/oauth2/callback
  # Callback from remote service to finalize authentication.
  #
  def oauth2
    auth_info = request.env['omniauth.auth']
    $stderr.puts "User::OmniauthCallbacksController.#{__method__} | #{request.method} | params #{params.inspect} | omniauth.auth = #{auth_info.inspect}"
    @user = User.from_omniauth(auth_info)
    if @user.persisted?
      $stderr.puts "User::OmniauthCallbacksController.#{__method__} | @user persisted"
      #sign_in_and_redirect(@user, event: :authentication)
      sign_in_and_redirect(@user)
      set_flash_message(:notice, :success, kind: 'Bookshare')
    else
      $stderr.puts "User::OmniauthCallbacksController.#{__method__} | USER NOT PERSISTED"
      #session['devise.oauth2_data'] = auth_info
      #redirect_to new_user_registration_url
      failure
    end
  end
=end

  # == GET  /users/auth/bookshare/callback
  # == POST /users/auth/bookshare/callback
  # Callback from the Bookshare auth service to finalize authentication.
  #
  def bookshare
    auth_info = request.env['omniauth.auth']
    $stderr.puts "User::OmniauthCallbacksController.#{__method__} | #{request.method} | params #{params.inspect} | omniauth.auth = #{auth_info.inspect}"
    @user = User.from_omniauth(auth_info)
    if @user.persisted?
      $stderr.puts "User::OmniauthCallbacksController.#{__method__} | @user persisted"
      #sign_in_and_redirect(@user, event: :authentication)
      sign_in_and_redirect(@user)
      set_flash_message(:notice, :success, kind: 'Bookshare')
    else
      $stderr.puts "User::OmniauthCallbacksController.#{__method__} | USER NOT PERSISTED"
      #session['devise.bookshare_data'] = auth_info
      #redirect_to new_user_registration_url
      failure
    end
  end

  # ???
  #
  def failure
    $stderr.puts "User::OmniauthCallbacksController.#{__method__} | #{request.method} | params #{params.inspect}"
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
