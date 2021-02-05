# app/controllers/user/sessions_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# User session controller.
#
# @!attribute [r] devise_mapping
#   @return [Devise::Mapping]
#
class User::SessionsController < Devise::SessionsController

  include SessionConcern
  include FlashConcern
  include BookshareConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION

    include AbstractController::Callbacks

    protected

    # @return [Devise::Mapping]
    # @private
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
    super
  end

  # == POST /users/sign_in
  #
  # Begin login session.
  #
  def create
    __debug_route
    __debug_request
    super do
      api_update(user: resource)
      set_flash_notice
    end
  rescue => error
    auth_failure_redirect(message: error)
  end

  # == DELETE /users/sign_out[?revoke=(true|false)]
  #
  # End login session.
  #
  # If the "revoke" parameter is missing or "true" then the local session is
  # ended _and_ its associated OAuth2 token is revoked.  If "revoke" is "false"
  # then only the local session is ended.
  #
  # @see SessionConcern#delete_token
  #
  def destroy
    __debug_route
    __debug_request
    username = current_user&.uid&.dup
    delete_token
    super do
      api_clear
      set_flash_notice(user: username)
    end
  rescue => error
    auth_failure_redirect(message: error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /users/sign_in_as?uid=NAME&token=AUTH_TOKEN
  # == GET /users/sign_in_as?auth=(OmniAuth::AuthHash)
  #
  # Sign in using information supplied outside of the OAuth2 flow.
  #
  # == Usage Notes
  # The initial request to this endpoint is redirected by Warden::Manager to
  # OmniAuth::Strategies::Bookshare#request_call.  The second request is
  # performed from OmniAuth::Strategies::Bookshare#callback_phase which
  # provides the value for 'omniauth.auth'.
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def sign_in_as
    __debug_route
    __debug_request
    self.resource = user = user_from_id || user_from_auth_data
    raise 'No authentication data' if user.blank?
    __debug do
      "#{__method__}: #{user.uid.inspect} #{session['omniauth.auth'].inspect}"
    end
    sign_in(resource_name, user)
    api_update(user: user)
    check_user_validity
    set_flash_notice(action: :create)
    auth_success_redirect
  rescue => error
    auth_failure_redirect(message: error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Lookup (and update) User by login name.
  #
  # @param [String, nil] uid          Default: params[:uid] or params[:id].
  # @param [String, nil] token        Default: params[:token]
  #
  # @return [User]                    The updated record of the indicated user.
  # @return [nil]                     No record for the indicated user.
  #
  def user_from_id(uid: nil, token: nil)
    uid ||= params[:uid] || params[:id]
    return unless (uid = uid.to_s.strip.presence)
    token  ||= params[:token]
    # noinspection RubyNilAnalysis
    user_name = uid.downcase
    session['omniauth.auth'] ||=
      OmniAuth::Strategies::Bookshare.synthetic_auth_hash(user_name, token)
    User.find_by(email: user_name).tap do |u|
      u.update(access_token: token) if u && token
    end
  end

  # Create a User from authentication data (from the session or from the
  # User table of the database).
  #
  # @param [OmniAuth::AuthHash, nil] auth_data  Default: params[:auth]
  #
  # @return [User]                    Updated record of the indicated user.
  # @return [nil]                     If `session['omniauth.auth']` is invalid.
  #
  def user_from_auth_data(auth_data = nil)
    new_auth =
      if auth_data.is_a?(OmniAuth::AuthHash)
        auth_data
      elsif !session['omniauth.auth']
        OmniAuth::Strategies::Bookshare.synthetic_auth_hash(params)
      end
    if new_auth
      session['omniauth.auth'] = new_auth
      OmniAuth::Strategies::Bookshare.stored_auth_update(new_auth)
    end
    User.from_omniauth(session['omniauth.auth'])
  end

  # Trigger an exception if the signed-in user doesn't have a valid Bookshare
  # OAuth2 token.
  #
  # @return [void]
  #
  # @raise [StandardError]  If Bookshare account info was unavailable.
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

# Devise attributes defined via Devise::Models, depending on the Devise
# configuration.
#
# @see Devise::Models#config
#
# :nocov:
unless ONLY_FOR_DOCUMENTATION
  # @private
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
