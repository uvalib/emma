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

  # == GET /users/sign_in
  # Prompt the user for login credentials.
  #
  def new
    $stderr.puts "User::SessionsController.#{__method__} | #{request.method} | params = #{params.inspect}"
    $stderr.puts "resource_class    = #{resource_class.inspect}"
    $stderr.puts "sign_in_params    = #{sign_in_params.inspect}"
    $stderr.puts "auth_options      = #{auth_options.inspect}"
    $stderr.puts "serialize_options = #{serialize_options(resource).inspect}"
    super
    rs = resource rescue nil # TODO: debugging - delete
    $stderr.puts "User::SessionsController.#{__method__} | #{request.method} | resource = #{rs.inspect}"
  end

  # == POST /users/sign_in
  # Begin login session.
  #
  def create
    $stderr.puts "User::SessionsController.#{__method__} | #{request.method} | params #{params.inspect}"
    super
    rs = resource rescue nil # TODO: debugging - delete
    $stderr.puts "User::SessionsController.#{__method__} | #{request.method} | resource = #{rs.inspect}"
  end

  # == DELETE /users/sign_out
  # End login session.
  #
  def destroy
    rs = resource rescue nil # TODO: debugging - delete
    $stderr.puts "User::SessionsController.#{__method__} | #{request.method} | params #{params.inspect}"
    $stderr.puts "User::SessionsController.#{__method__} | #{request.method} | resource = #{rs.inspect}"
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
