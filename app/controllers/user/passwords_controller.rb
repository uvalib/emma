# app/controllers/user/passwords_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class User::PasswordsController < Devise::PasswordsController

  include FlashConcern
  include SessionConcern
  include RunStateConcern

  # ===========================================================================
  # :section: Devise::PasswordsController overrides
  # ===========================================================================

  public

  # == GET /users/password/new
  #
  def new
    __debug_route
    super
  end

  # == POST /users/password
  #
  def create
    __debug_route
    __debug_request
    super
  end

  # == GET /users/password/edit[?reset_password_token=TOKEN]
  #
  def edit
    __debug_route
    super
  end

  # == PUT /users/password
  #
  def update
    __debug_route
    __debug_request
    super
  end

  # ===========================================================================
  # :section: Devise::PasswordsController overrides
  # ===========================================================================

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

end

__loading_end(__FILE__)
