# app/controllers/user/sessions_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# User session controller.
#
# !@attribute [r] devise_mapping
#   @return [Devise::Mapping]
#
class User::SessionsController < Devise::SessionsController

  include SessionConcern
  include FlashConcern

  # Non-functional hints for RubyMine.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION

    include AbstractController::Callbacks

    protected

    # @return [Devise::Mapping]
    def devise_mapping; end

  end
  # :nocov:

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  prepend_before_action :require_no_authentication,    only: %i[new create sign_in_as]
  prepend_before_action :allow_params_authentication!, only: %i[create sign_in_as]
  prepend_before_action :verify_signed_out_user,       only: %i[destroy]
  prepend_before_action :no_devise_timeout,            only: %i[create destroy sign_in_as]

=begin # TODO: configure_sign_in_params ???
  before_action :configure_sign_in_params, only: [:create]
=end

  # ===========================================================================
  # :section: Session management
  # ===========================================================================

  append_around_action :session_update

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /users/sign_in
  # Prompt the user for login credentials.
  #
  # This method overrides:
  # @see Devise::SessionsController#new
  #
  def new
    __debug_route
    super
  end

  # == POST /users/sign_in
  # Begin login session.
  #
  # This method overrides:
  # @see Devise::SessionsController#create
  #
  def create
    __debug_route
    __debug_request
    super do
      api_update(user: resource)
      set_flash_notice(__method__)
    end
  end

  # == DELETE /users/sign_out
  # End login session.
  #
  # This method overrides:
  # @see Devise::SessionsController#destroy
  #
  def destroy
    auth_data = session.delete('omniauth.auth')
    __debug_route { { "session['omniauth.auth']" => auth_data } }
    super do
      ApiService.clear
      set_flash_notice(__method__, auth_data)
    end
  end

  # == GET /users/sign_in_as?uid=NAME&token=AUTH_TOKEN
  # == GET /users/sign_in_as?auth={OmniAuth::AuthHash}
  # Sign in using information supplied outside of the OAuth2 flow.
  #
  # == Usage Notes
  # The initial request to this endpoint is redirected by Warden::Manager to
  # OmniAuth::Strategies::Bookshare#request_call.  The second request is
  # performed from OmniAuth::Strategies::Bookshare#callback_phase which
  # provides the value for 'omniauth.auth'.
  #
  def sign_in_as
    action = params[:action]
    uid    = params[:uid] || params[:id]
    token  = params[:token]
    data   = params[:auth]
    # noinspection RubyYardParamTypeMatch
    self.resource = user =
      uid &&
        user_from_id(action, uid, token) ||
        user_from_auth_data(action, data)
    sign_in(resource_name, user)
    api_update(user: user)
    set_flash_notice(:create)
    if params[:redirect]
      redirect_to params[:redirect]
    else
      redirect_to after_sign_in_path_for(user)
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
    flash_notice(I18n.t("emma.user.sessions.#{action}.success", user: user))
  end

  # Lookup (and update) User by login name.
  #
  # @param [Symbol, String] action
  # @param [String]         uid
  # @param [String, nil]    token
  #
  # @return [User]
  # @return [nil]
  #
  def user_from_id(action, uid, token = nil)
    user_name = uid.downcase
    __debug_route(action: action, uid: uid, token: (token || '-')) do
      { email: user_name }
    end
    session['omniauth.auth'] ||=
      OmniAuth::Strategies::Bookshare.synthetic_auth_hash(user_name, token)
    User.find_by(email: user_name).tap do |u|
      u&.update(access_token: token) if token
    end
  end

  # Create a User from authentication data (from the session or from the
  # User table of the database).
  #
  # @param [Symbol, String]          action
  # @param [OmniAuth::AuthHash, nil] auth_data
  #
  # @return [User]
  #
  def user_from_auth_data(action, auth_data = nil)
    session.delete('omniauth.auth') if auth_data.is_a?(OmniAuth::AuthHash)
    session['omniauth.auth'] ||= (
      auth_data || OmniAuth::Strategies::Bookshare.synthetic_auth_hash(params)
    ).tap { |data| OmniAuth::Strategies::Bookshare.stored_auth_update(data) }
    __debug_route(action: action, auth: (auth_data || '-')) do
      { "session['omniauth.auth']": session['omniauth.auth'] }
    end
    User.from_omniauth(session['omniauth.auth'])
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

=begin # TODO: configure_sign_in_params ???
  # If you have extra params to permit, append them to the sanitizer.
  #
  # @return [void]
  #
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  end
=end

end

# Devise attributes defined via Devise::Models, depending on the Devise
# configuration.
#
# @see Devise::Models#config
#
# :nocov:
unless ONLY_FOR_DOCUMENTATION
  class Devise::Mapping
    def authenticatable?          ; end
    def confirmable?              ; end
    def database_authenticatable? ; end
    def lockable?                 ; end
    def omniauthable?             ; end
    def recoverable?              ; end
    def registerable?             ; end
    def rememberable?             ; end
    def timeoutable?              ; end
    def validatable?              ; end
  end
end
# :nocov:

__loading_end(__FILE__)
