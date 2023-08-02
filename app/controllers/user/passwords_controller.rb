# app/controllers/user/passwords_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Individual EMMA account password maintenance.
#
# @see file:app/views/user/passwords/**
#
class User::PasswordsController < Devise::PasswordsController

  include SessionConcern
  include RunStateConcern
  include AuthConcern

  # ===========================================================================
  # :section: Devise::PasswordsController overrides
  # ===========================================================================

  public

  # === GET /users/password/new
  #
  def new
    __log_activity
    __debug_route
    super
  end

  # === POST /users/password
  #
  def create
    __log_activity
    __debug_route
    __debug_request
    super
  end

  # === GET /users/password/edit[?reset_password_token=TOKEN]
  #
  def edit
    __log_activity
    __debug_route
    super
  end

  # === PUT /users/password
  #
  def update
    __log_activity
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

   #The path used after sending reset password instructions
   #def after_sending_reset_password_instructions_path_for(resource_name)
   #  (resource_name)
   #end

end

__loading_end(__FILE__)
