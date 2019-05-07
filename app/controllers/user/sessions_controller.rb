# app/controllers/user/sessions_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# User session controller.
#
class User::SessionsController < Devise::SessionsController

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  public

  # before_action :configure_sign_in_params, only: [:create]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /user/sign_in
  # Prompt the user for login credentials.
  #
  def new
    __debug "User::SessionsController.#{__method__}"
   super
  end

  # == POST /user/sign_in
  # Begin login session.
  #
  def create
    __debug "User::SessionsController.#{__method__}"
    super
  end

  # == DELETE /user/sign_out
  # End login session.
  #
  def destroy
    __debug "User::SessionsController.#{__method__}"
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # If you have extra params to permit, append them to the sanitizer.
  #
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  end

end

__loading_end(__FILE__)
