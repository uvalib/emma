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
    self.resource = user = user_from_id || user_from_session
    raise 'No authentication data' if user.blank?
    __debug do
      "#{__method__}: #{user.account}: #{session['omniauth.auth'].inspect}"
    end
    if sign_in(resource_name, user).is_a?(TrueClass)
      __debug { "#{__method__}: #{user.account}}: was already signed in" }
    end
    user
  end

  # Sign out of the local (EMMA) session.
  #
  # @return [Boolean]                 False if there was no user.
  #
  # @see Devise::Controllers::SignInOut#sign_out
  #
  def local_sign_out
    delete_auth_data(caller: __method__)
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
  # @raise [RuntimeError]             If a User could not be found.
  #
  # @return [User]
  #
  def set_auth_data(src)
    src  = src.env                    if src.respond_to?(:env)
    src  = src['omniauth.auth']       if src.is_a?(Hash)
    src  = src.presence               or raise 'No auth data received' # TODO: I18n
    auth = OmniAuth::AuthHash.new(src)
    user = User.from_omniauth(auth)   or raise 'Could not locate user account' # TODO: I18n
    session['omniauth.auth'] = auth
    user
  end

  # Terminate the local login session ('omniauth.auth').
  #
  # @param [Symbol, nil] caller       Calling method for diagnostics.
  #
  # @return [OmniAuth::AuthHash, nil]
  #
  def delete_auth_data(caller: nil, **)
    caller ||= __method__
    session.delete('omniauth.auth').tap { |v|
      __debug { "#{caller}: omniauth.auth was: #{v.inspect}" } if v
    }.presence
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
    user   = (uid || params[:uid] || params[:id]).to_s.strip.presence
    user &&= User.find_by(email: user.downcase)
    session['omniauth.auth'] = auth_hash(user) if user
    user
  end

  # Find the User table entry matching current session authentication data.
  #
  # @return [User, nil]
  #
  def user_from_session
    User.from_omniauth(session['omniauth.auth'])
  end

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
