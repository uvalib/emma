# app/controllers/concerns/auth_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for authentication.
#
module AuthConcern

  extend ActiveSupport::Concern

  include Emma::Json
  include Emma::Debug

  include AuthHelper

  include ParamsConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Devise::Controllers::Helpers
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A table of pre-authorized user/token pairs for development purposes.        # if BS_AUTH
  # (Not generated for non-Rails-application executions.)
  #
  # Tokens are taken from the User table entries that have an :access_token
  # value.  If ENV['BOOKSHARE_TEST_AUTH'] is supplied, it is used to prime (or
  # update) database table.
  #
  # @type [Hash{String=>String}, nil]
  #
  CONFIGURED_AUTH ||=
    if BS_AUTH && rails_application?
      updates = json_parse(BOOKSHARE_TEST_AUTH).presence
      stored_auth_update(updates) if updates
      stored_auth_fetch.deep_freeze
    end

  # ===========================================================================
  # :section: Devise::Controllers::Helpers overrides
  # ===========================================================================

  protected

  # The "home" URL for a signed-in user.
  #
  # @param [User, Symbol] resource_or_scope
  #
  # @return [String]
  #
  def signed_in_root_path(resource_or_scope)
    user_scope?(resource_or_scope) ? dashboard_path : super
  end

  # The URL to which Devise redirects after signing in.
  #
  # @param [User, Symbol] resource_or_scope
  #
  # @return [String]
  #
  # === Implementation Notes
  # This does not use Devise::Controllers::StoreLocation#store_location_for
  # to avoid the potential of overwhelming session store by copying
  # session['app.current_path'] into session['user_return_to']. This seems to
  # be safe because the overridden function seems to be the only place where
  # that session entry is used.
  #
  def after_sign_in_path_for(resource_or_scope)
    return super unless user_scope?(resource_or_scope)
    path   = session.delete('app.devise.redirect')
    path ||= params[:redirect]
    path ||= get_current_path
    path   = nil if path == after_sign_out_path_for(resource_or_scope)
    path || signed_in_root_path(resource_or_scope)
  end

  # The URL to which Devise redirects after signing out.
  #
  # @param [User, Symbol] resource_or_scope
  #
  # @return [String]
  #
  def after_sign_out_path_for(resource_or_scope)
    user_scope?(resource_or_scope) ? welcome_path : super
  end

  # ===========================================================================
  # :section: Devise::Controllers::Helpers overrides
  # ===========================================================================

  private

  # Indicate whether the given resource/scope specifies the User resource.
  #
  # Returns *true* if *obj* cannot be interpreted as a scope or resource since
  # user scope is the assumed default.
  #
  # @param [User, Symbol, *] obj
  #
  # @see Devise::Mapping#find_scope!
  #
  def user_scope?(obj)
    if obj.is_a?(Class)
      mapping = Devise.mappings[:user]
      mapping.is_a?(Devise::Mapping) && obj.is_a?(mapping.to)
    elsif obj.is_a?(String) || obj.is_a?(Symbol)
      obj.to_sym == :user
    else
      true
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign in a local (EMMA) session.
  #
  # @return [User]
  #
  # @see Devise::Controllers::SignInOut#sign_in
  #
  def local_sign_in
    self.resource = user ||= user_from_id || user_from_auth_data
    raise 'No authentication data' if user.blank?
    __debug do
      "#{__method__}: #{user.uid}: #{session['omniauth.auth'].inspect}"
    end
    if sign_in(resource_name, user).is_a?(TrueClass)
      __debug { "#{__method__}: #{user.uid}}: was already signed in" }
    end
    user
  end

  # Sign out of the local (EMMA) session *without* revoking the OAuth2 token
  # (which signs out of the OAuth2 session).
  #
  # @return [Boolean]                 False if there was no user.
  #
  # @see Devise::Controllers::SignInOut#sign_out
  # @see #delete_auth_data
  #
  def local_sign_out
    auth = session.delete('omniauth.auth')
    __debug { "#{__method__}: omniauth.auth was: #{auth.inspect}" } if auth
    sign_out
  end

  # Sign out of the local session and the OAuth2 session.
  #
  # (This is the normal sign-out but named as a convenience for places in the
  # code where the distinction with #local_sign_out needs to be stressed.)
  #
  # @return [Boolean]                 False if there was no user.
  #
  # @note Currently unused.
  #
  def global_sign_out
    auth = session['omniauth.auth']
    __debug { "#{__method__}: omniauth.auth is: #{auth.inspect}" } if auth
    sign_out
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Set `session['omniauth.auth']` from `request.env['omniauth.auth']` and
  # return with the new or returning user.
  #
  # @param [ActionDispatch::Request, OmniAuth::AuthHash, Hash] src
  #
  # @raise [RuntimeError]             If *src* does not have auth data.
  # @raise [RuntimeError]             If a User could not be found or created.
  #
  # @return [User]
  #
  def set_auth_data(src)
    src = src.env                                  if src.respond_to?(:env)
    src = src['omniauth.auth']                     if src.is_a?(Hash)
    raise 'No authentication information received' if src.blank? # TODO: I18n
    auth = OmniAuth::AuthHash.new(src)
    user = User.from_omniauth(auth)
    raise 'Could not locate user account'          if user.blank? # TODO: I18n
    raise 'Could not create user account'          unless user.persisted? # TODO: I18n
    __debug_line { [__debug_route_label, 'user persisted'] }
    session['omniauth.auth'] = auth
    user
  end

  # Generate the authentication data to be associated with the given user.      # if BS_AUTH
  #
  # @param [User, String, Integer, *] user  Default: `#current_user`.           # if BS_AUTH
  #
  # @return [OmniAuth::AuthHash, nil]
  #
  def update_auth_data(user = nil)
    session['app.local.auth'] = nil
    user ||= current_user
    user &&= User.find_record(user) unless user.is_a?(User)
    if user && !user.is_bookshare_user?
      session['app.local.auth'] = auth_hash(user)
      session['omniauth.auth']  = auth_hash(user.bookshare_user)
    end
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # Terminate the local login session ('omniauth.auth').                        # unless BS_AUTH
  #
  # Terminate the local login session ('omniauth.auth') and the session with    # if BS_AUTH
  # the OAuth2 provider (if appropriate)
  #
  # @param [Boolean] no_revoke        If *true*, do not revoke the token with   # if BS_AUTH
  #                                     the OAuth2 provider.
  #
  # @return [void]
  #
  # _see #revoke_access_token                                                   # if BS_AUTH
  #
  def delete_auth_data(no_revoke: false)
    auth = session.delete('omniauth.auth')
    return unless BS_AUTH
    no_revoke_reason =
      case
        when auth.blank?      then 'NO TOKEN'
        when no_revoke        then 'no_revoke=true'
        when auth_debug_user? then "USER #{current_user.uid} DEBUGGING"
        when not_deployed?    then 'localhost'
      end
    if no_revoke_reason
      __debug { "#{__method__}: NOT REVOKING TOKEN - #{no_revoke_reason}" }
    else
      revoke_access_token(auth)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Lookup (and update) User by login name.
  #
  # @param [String, nil] uid          Default: params[:uid] or params[:id].
  #
  # @return [User]                    The updated record of the indicated user.
  # @return [nil]                     No record for the indicated user.
  #
  def user_from_id(uid = nil)
    uid  = (uid || params[:uid] || params[:id]).to_s.strip.presence&.downcase
    user = uid && User.find_by(email: uid) or return
    auth = auth_hash(user)
    if BS_AUTH && auth&.dig(:credentials, :token).blank?
      # noinspection RubyMismatchedArgumentType
      auth  = synthetic_auth_hash(uid)
      token = auth&.dig(:credentials, :token)
      user.update(access_token: token) if token.present?
    end
    session['omniauth.auth'] = auth
    user
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
    auth = (auth_data if auth_data.is_a?(OmniAuth::AuthHash))
    if BS_AUTH
      auth ||= (synthetic_auth_hash(params) unless session['omniauth.auth'])
      stored_auth_update(auth) if auth
    end
    if auth
      session['omniauth.auth'] = auth
    else
      auth = session['omniauth.auth']
    end
    User.from_omniauth(auth)
  end

  # user_from_session
  #
  # @return [User, nil]
  #
  def user_from_session
    if BS_AUTH
      if (auth = session['app.local.auth']).present?
        User.find_record(auth['uid'])
      elsif (auth = session['omniauth.auth']).present?
        User.from_omniauth(auth)
      end
    else
      User.from_omniauth(session['omniauth.auth'])
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether the user is one is capable of short-circuiting the         # if BS_AUTH
  # authorization process.
  #
  # @param [User, String, nil] user   Default: `#current_user`
  #
  def auth_debug_user?(user = nil)
    uid = User.uid_value(user || current_user)
    session.key?('app.debug') && stored_auth.key?(uid)
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # revoke_access_token                                                         # if BS_AUTH
  #
  # @param [Hash, nil] auth           Default: `session['omniauth.auth']`.
  #
  # @return [OAuth2::Response]
  # @return [nil]                     If no token was provided or found.
  #
  #--
  # noinspection RubyResolve
  #++
  def revoke_access_token(auth = nil)
    auth  ||= session['omniauth.auth']
    auth    = OmniAuth::AuthHash.new(auth) if auth.is_a?(Hash)
    token   = (auth&.credentials&.token if auth.is_a?(OmniAuth::AuthHash))
    return Log.warn { "#{__method__}: no token present" } if token.blank?
    Log.info { "#{__method__}: #{token.inspect}" }

    opt     = auth_default_options
    id      = opt.client_id
    secret  = opt.client_secret
    options = opt.client_options.deep_symbolize_keys
    __debug_line(__method__) { { id: id, secret: secret, options: options } }

    OAuth2::Client.new(id, secret, options).auth_code.revoke_token(token)
  end
    .tap { |meth| disallow(meth) unless BS_AUTH }

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # @private
  #
  # Devise attributes defined via Devise::Models, depending on the Devise
  # configuration.
  #
  # @see Devise::Models#config
  #
  class Devise::Mapping
    def authenticatable?          ; end # @see Devise::Mapping#authenticatable?
    def confirmable?              ; end # @see Devise::Mapping#add_module
    def database_authenticatable? ; end # @see Devise::Mapping#add_module
    def lockable?                 ; end # @see Devise::Mapping#add_module
    def omniauthable?             ; end # @see Devise::Mapping#add_module
    def recoverable?              ; end # @see Devise::Mapping#add_module
    def registerable?             ; end # @see Devise::Mapping#add_module
    def rememberable?             ; end # @see Devise::Mapping#add_module
    def timeoutable?              ; end # @see Devise::Mapping#add_module
    def validatable?              ; end # @see Devise::Mapping#add_module
  end

  # :nocov:
end

__loading_end(__FILE__)
