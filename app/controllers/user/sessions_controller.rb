# app/controllers/user/sessions_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# User session controller.
#
# @see file:app/views/user/sessions/**
#
class User::SessionsController < Devise::SessionsController

  include ApiConcern
  include AuthConcern
  include SessionConcern
  include RunStateConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include AbstractController::Callbacks
  end
  # :nocov:

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  NO_AUTH    = [:new, :create, :sign_in_local, *SIGN_IN_AS].freeze
  PARAM_AUTH = [:create, :sign_in_local, *SIGN_IN_AS].freeze
  NO_TIMEOUT = [:create, :destroy, *SIGN_IN_AS].freeze

  prepend_before_action :require_no_authentication,    only: NO_AUTH
  prepend_before_action :allow_params_authentication!, only: PARAM_AUTH
  prepend_before_action :verify_signed_out_user,       only: %i[destroy]
  prepend_before_action :no_devise_timeout,            only: NO_TIMEOUT

  # ===========================================================================
  # :section: Session management
  # ===========================================================================

  append_around_action :session_update

  # ===========================================================================
  # :section: Devise::SessionsController overrides
  # ===========================================================================

  public

  # === GET /users/sign_in
  #
  # Prompt the user for login credentials.
  #
  # @see #new_user_session_path       Route helper
  #
  def new
    __log_activity
    __debug_route
    opt  = request_parameters
    mode = opt.delete(:mode)&.to_sym
    if mode == :local
      redirect_to opt.merge(action: :sign_in_local)
    else
      super
    end
  end

  # === POST /users/sign_in
  #
  # Begin login session.
  #
  # @see #user_session_path           Route helper
  #
  def create
    __debug_route
    __debug_request
    self.resource = warden.authenticate!(auth_options)
    __log_activity("LOGIN #{resource}")
    remember_dev(resource)
    set_flash_notice
    sign_in_and_redirect(resource)
  rescue => error
    auth_failure_redirect(message: error)
  end

  # === DELETE /users/sign_out[?revoke=(true|false)]
  #
  # End login session.
  #
  # @see #destroy_user_session_path   Route helper
  # @see AuthConcern#delete_auth_data
  #
  def destroy
    __log_activity("LOGOUT #{current_user}")
    __debug_route
    __debug_request
    user = current_user&.account&.dup
    delete_auth_data(caller: __method__)
    super
    api_clear(user: user)
    set_flash_notice(user: user, clear: true)
  rescue => error
    auth_failure_redirect(message: error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /users/sign_in_local
  #
  # Sign in with an EMMA user account encrypted password.
  #
  # @see #sign_in_local_path          Route helper
  #
  def sign_in_local
    __log_activity
    __debug_route
  end

  # === GET /users/sign_in_as?id=NAME&token=AUTH_TOKEN
  # === GET /users/sign_in_as?uid=NAME&token=AUTH_TOKEN
  # === GET /users/sign_in_as?auth=(OmniAuth::AuthHash)
  #
  # Sign in using authorization information supplied outside the normal
  # authorization flow.
  #
  # @see #sign_in_as_path             Route helper
  # @see AuthConcern#local_sign_in
  #
  def sign_in_as
    __debug_route
    __debug_request
    local_sign_in
    __log_activity("LOGIN #{resource}")
    set_flash_notice(action: :create)
    auth_success_redirect
  rescue => error
    auth_failure_redirect(message: error)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Called to avoid timing-out waiting for credentials.
  #
  # @return [void]
  #
  def no_devise_timeout
    request.env['devise.skip_timeout'] = true
  end

end

__loading_end(__FILE__)
