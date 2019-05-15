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

  prepend_before_action :require_no_authentication,    only: %i[new create sign_in_as]
  prepend_before_action :allow_params_authentication!, only: %i[create sign_in_as]
  prepend_before_action :verify_signed_out_user,       only: %i[destroy]
  prepend_before_action(only: %i[create destroy sign_in_as]) do
    request.env['devise.skip_timeout'] = true
  end
  # before_action :configure_sign_in_params, only: [:create]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /users/sign_in
  # Prompt the user for login credentials.
  #
  def new
    super
  end

  # == POST /users/sign_in
  # Begin login session.
  #
  def create
    super do
      ApiService.update(user: resource)
      set_flash_notice(__method__)
    end
  end

  # == DELETE /users/sign_out
  # End login session.
  #
  def destroy
    auth = session.delete('omniauth.auth')
    super do
      ApiService.clear
      set_flash_notice(__method__, auth)
    end
  end

  # == GET /users/sign_in_as?id=:id
  # Sign in as a specific user.
  #
  # == Usage Notes
  # This can only be used if OmniAuth::Strategies::Bookshare::CONFIGURED_AUTH
  # exists and contains pre-fetched OAuth2 bearer tokens.
  #
  def sign_in_as
    auth = session['omniauth.auth'] ||=
      OmniAuth::Strategies::Bookshare.configured_auth_hash(params[:id])
    self.resource = warden.set_user(User.from_omniauth(auth))
    sign_in(resource_name, resource)
    ApiService.update(user: resource)
    set_flash_notice(:create)
    if params[:redirect]
      redirect_to params[:redirect]
    else
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Set `flash[:notice]` based on the current action and user name.
  #
  # @param [Symbol, String]          action
  # @param [String, Hash, User, nil] user     Default: `current_user`.
  #
  # @return [void]
  #
  def set_flash_notice(action, user = nil)
    user ||= resource
    user = user['uid']    if user.is_a?(Hash)
    user = user.uid       if user.respond_to?(:uid)
    user = 'unknown user' if user.blank?
    user = user.to_s
    flash[:notice] = t("emma.user.sessions.#{action}.success", user: user)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # If you have extra params to permit, append them to the sanitizer.
  #
  # @return [void]
  #
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  end

end

__loading_end(__FILE__)
