# app/controllers/concerns/session_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller callbacks and support methods for working with `session`.
#
module SessionConcern

  extend ActiveSupport::Concern

  include Emma::Debug

  include ParamsConcern
  include FlashConcern
  include ApiConcern
  include AuthConcern

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
  # :section:
  # ===========================================================================

  public

  # Redirect after a successful authorization operation.
  #
  # @param [String, nil] path         Default: `#after_sign_in_path_for`.
  # @param [User, nil]   user         Default: `#resource`.
  # @param [*]           message      Optionally passed to #flash_notice.
  #
  def auth_success_redirect(path = nil, user: nil, message: nil)
    set_flash_notice(message) if message.present?
    path ||= after_sign_in_path_for(user || resource)
    redirect_to path
  end

  # Redirect after a failed authorization operation.
  #
  # @param [String, nil] path         Default: `#after_sign_out_path_for`.
  # @param [User, nil]   user         Default: `#resource`.
  # @param [*]           message      Optionally passed to #flash_alert.
  #
  def auth_failure_redirect(path = nil, user: nil, message: nil)
    Log.info { "#{__method__}: #{message.inspect}" }
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
  def set_flash_notice(message = nil, action: nil, user: nil)
    message ||= status_message(status: :success, action: action, user: user)
    # noinspection RubyMismatchedParameterType
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
  def set_flash_alert(message = nil, action: nil, user: nil)
    message ||= status_message(status: :failure, action: action, user: user)
    # noinspection RubyMismatchedParameterType
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
    user     = user[:uid] || user['uid'] if user.is_a?(Hash)
    user     = user.uid                  if user.respond_to?(:uid)
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
    session_section('app.last_op')
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
  # :section: Exception handlers
  # ===========================================================================

  public

  # Respond to the situation in which an authenticated user attempted to access
  # a route that is not allowed by the user's role.
  #
  # @param [CanCan::AccessDenied] exception
  #
  # @return [Any]
  #
  def access_denied_handler(exception)
    __debug_exception('RESCUE_FROM', exception)
    redirect_back(fallback_location: root_path, alert: exception.message)
  end

  # Respond to page failures due to a failure to communicate with a remote
  # service.
  #
  # @param [Api::Error, Faraday::Error] exception
  #
  # @return [nil]                     If not handled.
  # @return [Any]                     Otherwise.
  #
  def connection_error_handler(exception)
    __debug_exception('RESCUE_FROM', exception)
    if rendering_html?
      flash_now_alert(exception) if flash.now[:alert].blank?
      render
    end
  end

  # Respond to general page failures.
  #
  # @param [Exception] exception
  #
  # @return [nil]                     If not handled.
  # @return [Any]                     Otherwise.
  #
  def fallback_error_handler(exception)
    __debug_exception('RESCUE_FROM', exception, trace: true)
    if rendering_html?
      flash_now_alert(exception) if flash.now[:alert].blank?
      render
    elsif posting_html?
      redirect_back(fallback_location: root_path, alert: exception.message)
    end
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
    return if (t_last = last_operation_time).zero?
    return if (t_boot = BOOT_TIME.to_i) < t_last
    __debug  { "last_operation_time #{t_last} < BOOT_TIME #{t_boot}" }
    Log.info { "Signed out #{current_user&.to_s || 'user'} after reboot." }
    forget_dev
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
  # noinspection RubyMismatchedParameterType
  #++
  def session_update
    error = nil
    yield

  rescue CanCan::AccessDenied => error
    # Dealing with this condition here directly allows the intended redirect to
    # happen.  Otherwise (either by invoking rescue_with_handler here or by
    # re-raising to defer to rescue_from) the unauthorized page will get built
    # and displayed instead of redirecting.
    error = nil if access_denied_handler(error)

  rescue => error
    __debug_exception('UNHANDLED EXCEPTION', error, trace: true)
    flash_now_alert(*api_error_message) if api_error?

  ensure
    last_operation_update
    raise error if error
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    include SerializationHelper

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include AbstractController::Callbacks::ClassMethods
      include SessionConcern
      # :nocov:
    end

    # =========================================================================
    # :section: Session management
    # =========================================================================

    prepend_before_action :session_check,  unless: :devise_controller?
    before_action         :cleanup_session
    append_around_action  :session_update, if: :session_updatable?

    # =========================================================================
    # :section: Exceptions
    # =========================================================================

    rescue_from CanCan::AccessDenied, with: :access_denied_handler
    rescue_from ExecError,            with: :connection_error_handler
    rescue_from Faraday::Error,       with: :connection_error_handler
    rescue_from Net::ProtocolError,   with: :connection_error_handler
    rescue_from Timeout::Error,       with: :connection_error_handler
    rescue_from StandardError,        with: :fallback_error_handler

    # =========================================================================
    # :section: DeviseController overrides
    # =========================================================================

    if ancestors.include?(DeviseController)

      # This overrides the DeviseController message to allow the standard
      # 'already_authenticated' flash message to be overridden by
      # `session['app.devise.failure.message']`.
      #
      # @see UserConcern#role_failure
      #
      def require_no_authentication
        super
        flash_message = session.delete('app.devise.failure.message')
        flash_alert(flash_message) if flash_message
      end

    end

  end

end

__loading_end(__FILE__)
