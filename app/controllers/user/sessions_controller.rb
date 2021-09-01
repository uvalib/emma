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

  include AuthConcern
  include FlashConcern
  include SessionConcern
  include RunStateConcern
  include BookshareConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    # :nocov:
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  prepend_before_action :require_no_authentication,    only: %i[new create sign_in_local sign_in_as]
  prepend_before_action :allow_params_authentication!, only: %i[create sign_in_local sign_in_as]
  prepend_before_action :verify_signed_out_user,       only: %i[destroy]
  prepend_before_action :no_devise_timeout,            only: %i[create destroy sign_in_as]

  # ===========================================================================
  # :section: Session management
  # ===========================================================================

  append_around_action :session_update

  # ===========================================================================
  # :section: Devise::SessionsController overrides
  # ===========================================================================

  public

  # == GET /users/sign_in
  #
  # Prompt the user for login credentials.
  #
  def new
    __debug_route
    opt  = request_parameters
    mode = opt.delete(:mode)&.to_sym
    if mode == :local
      redirect_to **opt.merge(action: :sign_in_local)
    else
      super
    end
  end

  # == POST /users/sign_in
  #
  # Begin login session.
  #
  # @see AuthConcern#update_auth_data
  #
  def create
    __debug_route
    __debug_request
    update_auth_data
    self.resource = warden.authenticate!(auth_options)
    api_update(user: resource.bookshare_user)
    check_dev
    set_flash_notice
    sign_in_and_redirect(resource)
  rescue => error
    auth_failure_redirect(message: error)
    re_raise_if_internal_exception(error)
  end

  # == DELETE /users/sign_out[?revoke=(true|false)]
  #
  # End login session.
  #
  # If the "no_revoke" parameter is missing or "false" then the local session
  # is  ended _and_ its associated OAuth2 token is revoked.  If "no_revoke" is
  # "true" then only the local session is ended.
  #
  # @see AuthConcern#delete_auth_data
  #
  def destroy
    __debug_route
    __debug_request
    remember_dev
    user = current_user&.uid&.dup
    delete_auth_data(no_revoke: true?(params[:no_revoke]))
    super
    api_clear
    set_flash_notice(user: user)
  rescue => error
    auth_failure_redirect(message: error)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /users/sign_in_local
  #
  # Sign in with a local EMMA username/password.
  #
  def sign_in_local
    __debug_route
  end

  # == GET /users/sign_in_as?uid=NAME&token=AUTH_TOKEN
  # == GET /users/sign_in_as?auth=(OmniAuth::AuthHash)
  #
  # Sign in using information supplied outside of the OAuth2 flow.
  #
  # @see AuthConcern#local_sign_in
  #
  # == Usage Notes
  # The initial request to this endpoint is redirected by Warden::Manager to
  # OmniAuth::Strategies::Bookshare#request_call.  The second request is
  # performed from OmniAuth::Strategies::Bookshare#callback_phase which
  # provides the value for 'omniauth.auth'.
  #
  def sign_in_as
    __debug_route
    __debug_request
    user = local_sign_in
    api_update(user: user)
    check_user_validity
    set_flash_notice(action: :create)
    auth_success_redirect
  rescue => error
    auth_failure_redirect(message: error)
    re_raise_if_internal_exception(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Trigger an exception if the signed-in user doesn't have a valid Bookshare
  # OAuth2 token.
  #
  # @raise [RuntimeError]   If Bookshare account info was unavailable.
  #
  # @return [void]
  #
  def check_user_validity
    bs_api.get_user_identity
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Called to avoid timing-out waiting for credentials.
  #
  def no_devise_timeout
    request.env['devise.skip_timeout'] = true
  end

end

__loading_end(__FILE__)
