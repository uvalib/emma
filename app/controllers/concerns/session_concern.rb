# app/controllers/concerns/session_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller callbacks and support methods for working with `session`.
#
module SessionConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'SessionConcern')

    include SerializationHelper

    # Non-functional hints for RubyMine type checking.
    # :nocov:
    unless ONLY_FOR_DOCUMENTATION
      include AbstractController::Callbacks::ClassMethods
      include SessionConcern
    end
    # :nocov:

    # =========================================================================
    # :section: Session management
    # =========================================================================

    prepend_before_action :session_check,  unless: :devise_controller?
    before_action         :cleanup_session
    append_around_action  :session_update, if: :session_updatable?

    # =========================================================================
    # :section: Exceptions
    # =========================================================================

    rescue_from CanCan::AccessDenied do |exception|
      __debug_exception('RESCUE_FROM', exception)
      redirect_to dashboard_path, alert: exception.message
    end

    rescue_from Api::Error, Faraday::Error do |exception|
      __debug_exception('RESCUE_FROM', exception)
      if rendering_html?
        flash_now_alert(exception) if flash.now[:alert].blank?
        render
      end
    end

    rescue_from StandardError do |exception|
      __debug_exception('RESCUE_FROM', exception, trace: true)
      if rendering_html?
        flash_now_alert(exception) if flash.now[:alert].blank?
        render
      elsif posting_html?
        flash_alert(exception)
        redirect_back(fallback_location: root_path)
      end
    end

  end

  include Emma::Debug
  include ParamsConcern
  include FlashConcern
  include ApiConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  include Devise::Controllers::Helpers unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Keys for session values that should not be touched by #cleanup_session.
  #
  # Note that all 'devise.*', 'omniauth.*' and 'warden.*' entries are preserved
  # because any entry with a '.' in its key name is preserved.
  #
  # @type [Array<String,Regexp>]
  #
  PRESERVE_SESSION_KEYS = [
    'flash',
    'session_id',
    '_csrf_token',
    '_turbolinks_location',
    /\./,
    /_return_to$/,
  ].freeze

  # ===========================================================================
  # :section: Devise::Controllers::Helpers overrides
  # ===========================================================================

  protected

  # after_sign_in_path_for
  #
  # @param [Object] resource_or_scope
  #
  # @return [String]
  #
  # == Implementation Notes
  # This does not use Devise::Controllers::StoreLocation#store_location_for
  # to avoid the potential of overwhelming session store by copying
  # session['current_path'] into session['user_return_to']. This seems to be
  # safe because the overridden function seems to be the only place where that
  # session entry is used.
  #
  def after_sign_in_path_for(resource_or_scope)
    path = get_current_path
    path = dashboard_path if path.nil? || (path == welcome_path)
    path
  end

  # after_sign_out_path_for
  #
  # @return [String]
  #
  def after_sign_out_path_for(*)
    welcome_path
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Redirect after a successful authorization operation.
  #
  # @param [String, nil]       path     Default: `#after_sign_in_path_for`.
  # @param [String, User, nil] user     Default: `#resource`.
  # @param [*]                 message  Optionally passed to #flash_notice.
  #
  def auth_success_redirect(path = nil, user: nil, message: nil)
    set_flash_notice(message) if message.present?
    path ||= params[:redirect] || after_sign_in_path_for(user || resource)
    redirect_to path
  end

  # Redirect after a failed authorization operation.
  #
  # @param [String, nil]       path     Default: `#after_sign_out_path_for`.
  # @param [String, User, nil] user     Default: `#resource`.
  # @param [*]                 message  Optionally passed to #flash_alert.
  #
  def auth_failure_redirect(path = nil, user: nil, message: nil)
    local_sign_out # Make sure no remnants of the local session are left.
    set_flash_alert(message) if message.present?
    path ||= after_sign_out_path_for(user || resource)
    redirect_to path
  end

  # Set `flash[:notice]` based on the current action and user name.
  #
  # @param [String, nil]             message
  # @param [Symbol, nil]             action   Default: `params[:action]`.
  # @param [String, Hash, User, nil] user     Default: `current_user`.
  #
  # @return [void]
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def set_flash_notice(message = nil, action: nil, user: nil)
    message ||= status_message(status: :success, action: action, user: user)
    flash_notice(message)
  end

  # Set `flash[:alert]` based on the current action and user name.
  #
  # @param [String, nil]             message
  # @param [Symbol, nil]             action   Default: `params[:action]`.
  # @param [String, Hash, User, nil] user     Default: `current_user`.
  #
  # @return [void]
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def set_flash_alert(message = nil, action: nil, user: nil)
    message ||= status_message(status: :failure, action: action, user: user)
    flash_alert(message)
  end

  # Configured success or failure message.
  #
  # @param [String, Symbol]          status
  # @param [Symbol, nil]             action   Default: `params[:action]`.
  # @param [String, Hash, User, nil] user     Default: `current_user`.
  #
  # @return [String]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def status_message(status:, action: nil, user: nil)
    action ||= params[:action]
    user   ||= resource
    user     = user['uid'] if user.is_a?(Hash)
    user     = user.uid    if user.respond_to?(:uid)
    user     = user.to_s.presence || 'unknown user' # TODO: I18n
    I18n.t("emma.user.sessions.#{action}.#{status}", user: user)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Information about the last operation performed in this session.
  #
  # @return [Hash]
  #
  def last_operation
    session_section('last_op')
  end

  # Time of the last operation performed in this session.
  #
  # @return [Integer]
  #
  def last_operation_time
    last_operation['time'].to_i
  end

  # Persist information about the last operation performed in this session.
  #
  # @param [Time]   time              Default: `Time.now`.
  # @param [String] path              Default: `request.path`.
  # @param [Hash]   req_params        Default: `params`.
  #
  # @return [Hash{String=>*}]
  #
  def last_operation_update(time: nil, path: nil, req_params: nil)
    req_params ||= params
    # noinspection RubyCaseWithoutElseBlockInspection
    case req_params[:controller]
      when 'api' then return if req_params[:action] == 'image'
    end
    last_operation.merge!(
      'time'   => (time || Time.now).to_i,
      'path'   => (path || request_path),
      'params' => url_parameters(req_params)
    )
      .tap do
        __debug { "session_update 'time' = #{last_operation_time.inspect}" }
      end
  end

  # Application-specific `#session` keys.
  #
  # @return [Array<String>]
  #
  def session_keys
    session.keys.reject do |key|
      PRESERVE_SESSION_KEYS.any? do |ignore_key|
        ignore_key.is_a?(Regexp) ? key.match?(ignore_key) : (key == ignore_key)
      end
    end
  end

  # Indicate whether handling of the current request should be wrapped by
  # #session_update.
  #
  def session_updatable?
    !devise_controller? && !request_xhr?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign out of the local (EMMA) session *without* revoking the OAuth2 token
  # (which signs out of the OAuth2 session).
  #
  # @see Devise::Controllers::SignInOut#sign_out
  # @see #delete_token
  #
  def local_sign_out
    token = session.delete('omniauth.auth')
    __debug { "#{__method__}: omniauth.auth was: #{token.inspect}" } if token
    sign_out
  end

  # Sign out of the local session and the OAuth2 session.
  #
  # (This is the normal sign-out but named as a convenience for places in the
  # where the distinction with #local_sign_out needs to be stressed.)
  #
  def global_sign_out
    token = session['omniauth.auth']
    __debug { "#{__method__}: omniauth.auth is: #{token.inspect}" } if token
    sign_out
  end

  # Terminate the local login session ('omniauth.auth') and the session with
  # the OAuth2 provider (if appropriate)
  #
  # @param [Boolean] revoke           If set to *false*, do not revoke the
  #                                     token with the OAuth2 provider.
  #
  # @return [void]
  #
  # @see #revoke_access_token
  #
  def delete_token(revoke: true)
    token = session.delete('omniauth.auth')
    return unless revoke
    no_revoke_reason =
      if !application_deployed?
        'localhost'
      elsif debug_user?
        "USER #{current_user.uid} DEBUGGING"
      elsif false?(params[:revoke])
        'revoke=false'
      elsif token.blank?
        'NO TOKEN'
      end
    if no_revoke_reason
      __debug { "#{__method__}: NOT REVOKING TOKEN - #{no_revoke_reason}" }
    else
      revoke_access_token(token)
    end
  end

  # Indicate whether the user is one is capable of short-circuiting the
  # authorization process.
  #
  # @param [User, String, nil] user   Default: `#current_user`
  #
  def debug_user?(user = nil)
    # noinspection RubyYardParamTypeMatch
    session.key?('debug') &&
      OmniAuth::Strategies::Bookshare.debug_user?(user || current_user)
  end

  # revoke_access_token
  #
  # @param [Hash, nil] token          Default: `session['omniauth.auth']`.
  #
  # @return [OAuth2::Response]
  # @return [nil]                     If no token was provided or found.
  #
  #--
  # noinspection RubyNilAnalysis, RubyResolve
  #++
  def revoke_access_token(token = nil)
    token ||= session['omniauth.auth']
    token   = OmniAuth::AuthHash.new(token) if token.is_a?(Hash)
    token   = token.credentials.token       if token.is_a?(OmniAuth::AuthHash)
    return Log.warn { "#{__method__}: no token present" } if token.blank?
    Log.info { "#{__method__}: #{token.inspect}" }

    # @type [OmniAuth::Strategy::Options] opt
    opt     = OmniAuth::Strategies::Bookshare.default_options
    id      = opt.client_id
    secret  = opt.client_secret
    options = opt.client_options.deep_symbolize_keys
    __debug_line(__method__) { { id: id, secret: secret, options: options } }

    OAuth2::Client.new(id, secret, options).auth_code.revoke_token(token)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Clean out empty session values.
  #
  # @return [void]
  #
  def cleanup_session
    return unless request.get?
    # noinspection RubyCaseWithoutElseBlockInspection
    case params[:controller]
      when 'api'      then return if params[:action] == 'image'
      when 'artifact' then return if params[:action] == 'show'
    end
    session_keys.each do |key|
      value = session[key]
      session.delete(key) if value.is_a?(Hash) ? value.empty? : value.nil?
    end
  end

  # If a reboot occurred since the last session update, ensure consistency by
  # performing a sign-out and cleaning up related session data.
  #
  # @return [void]
  #
  # == Usage Notes
  # This must be invoked as a :before_action.
  #
  def session_check
    return if (t_boot = BOOT_TIME.to_i) < (t_last = last_operation_time)
    if t_last.nonzero?
      __debug  { "last_operation_time #{t_last} < BOOT_TIME #{t_boot}" }
      Log.info { "Signed out #{current_user&.to_s || 'user'} after reboot." }
    end
    local_sign_out
    @reset_browser_cache = true
  end

  # Remember the last operation performed in this session and set the flash
  # alert if there was an unprocessed ApiSession exception.
  #
  # @raise [Exception]                Propagated if raised by the block.
  #
  # == Usage Notes
  # This must be invoked as an :around_action.
  #
  # == Implementation Notes
  # The "ensure" block is executed before the ApplicationController
  # "rescue_from".  However, note that Rails is doing something with "$!" which
  # causes Faraday::ClientError to be the exception that's acted upon in that
  # block, whereas :api_error_message shows the BookshareService::Error that is
  # created in BookshareService::Common#api.
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def session_update
    error = nil
    yield
  rescue => error
    __debug_exception('UNHANDLED EXCEPTION', error, trace: true)
    flash_now_alert(*api_error_message) if api_error?
  ensure
    last_operation_update
    raise error if error
  end

end

__loading_end(__FILE__)
