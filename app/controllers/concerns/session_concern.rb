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

  include FlashHelper

  include ApiConcern
  include AuthConcern
  include ParamsConcern
  include SerializationConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Devise::Controllers::Helpers
  end
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
  # :section:
  # ===========================================================================

  public

  # Redirect after a successful authorization operation.
  #
  # @param [String, nil] path         Default: `#after_sign_in_path_for`.
  # @param [User, nil]   user         Default: `#resource`.
  # @param [any, nil]    message      Passed to #set_flash_notice.
  # @param [Hash]        opt          Passed to #set_flash_notice.
  #
  def auth_success_redirect(path = nil, user: nil, message: nil, **opt)
    set_flash_notice(message, **opt) if message.present?
    path ||= after_sign_in_path_for(user || resource)
    redirect_to path
  end

  # Redirect after a failed authorization operation.
  #
  # @param [String, nil] path         Default: `#after_sign_out_path_for`.
  # @param [User, nil]   user         Default: `#resource`.
  # @param [any, nil]    message      Passed to #set_flash_notice.
  # @param [Hash]        opt          Passed to #set_flash_alert.
  #
  def auth_failure_redirect(path = nil, user: nil, message: nil, **opt)
    Log.info { "#{__method__}: #{message.inspect}" }
    local_sign_out # Make sure no remnants of the local session are left.
    re_raise_if_internal_exception(message) if message.is_a?(Exception)
    set_flash_alert(message, **opt)         if message.present?
    path ||= after_sign_out_path_for(user || resource)
    redirect_to path
  end

  # Set `flash[:notice]` based on the current action and username.
  #
  # @param [any, nil]                message  String
  # @param [Symbol, nil]             action   Default: `params[:action]`.
  # @param [String, Hash, User, nil] user     Default: `current_user`.
  # @param [Hash]                    opt      Passed to #flash_notice.
  #
  # @return [void]
  #
  def set_flash_notice(message = nil, action: nil, user: nil, **opt)
    message ||= status_message(status: :success, action: action, user: user)
    flash_notice(*message, **opt)
  end

  # Set `flash[:alert]` based on the current action and username.
  #
  # @param [any, nil]                message  String
  # @param [Symbol, nil]             action   Default: `params[:action]`.
  # @param [String, Hash, User, nil] user     Default: `current_user`.
  # @param [Hash]                    opt      Passed to #flash_alert.
  #
  # @return [void]
  #
  def set_flash_alert(message = nil, action: nil, user: nil, **opt)
    message ||= status_message(status: :failure, action: action, user: user)
    flash_alert(*message, **opt)
  end

  # Configured success or failure message.
  #
  # @param [String, Symbol]          status
  # @param [Symbol, nil]             action   Default: `params[:action]`.
  # @param [String, Hash, User, nil] user     Default: `current_user`.
  #
  # @return [String]
  #
  def status_message(status:, action: nil, user: nil)
    action ||= params[:action]
    user   ||= resource
    user     = user[:uid] || user['uid'] if user.is_a?(Hash)
    user     = user.account              if user.respond_to?(:account)
    user     = user.to_s.presence || config_term(:session, :unknown_user)
    # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
    config_page(:user_sessions, action, status, user: user)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Persist information about the last operation performed in this session.
  #
  # @param [Time]   time              Default: `Time.now`.
  # @param [String] path              Default: `request.path`.
  #
  # @return [Hash{String=>any,nil}, nil]
  #
  def last_operation_update(time: nil, path: nil)
    return if (params[:controller] == 'search') && (params[:action] == 'image')
    last_operation.merge!(
      'time'   => (time || Time.now).to_i,
      'path'   => (path || request_path),
      'params' => abbreviate_params!(url_parameters)
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

  protected

  # Parameters that are not abbreviated in #last_operation['params'].
  #
  # @type [Array<Symbol>]
  #
  LAST_OP_NO_ABBREV = %i[redirect].freeze

  # Maximum size for the rendered result of #last_operation['params'].
  #
  # @type [Integer]
  #
  MAX_LAST_OP_PARAMS = 256

  # Maximum size for any individual item within the rendered result of
  # #last_operation['params'].
  #
  # @type [Integer]
  #
  MAX_LAST_OP_PARAM = 64

  # Substitution for a Hash-valued parameter in #last_operation['params'].
  #
  # @type [String]
  #
  HASH_PLACEHOLDER = '{...}'

  # Substitution for an Array-valued parameter in #last_operation['params'].
  #
  # @type [String]
  #
  ARRAY_PLACEHOLDER = '[...]'

  # Since #last_operation parameters are only for dev purposes, this method is
  # used to reduce the reported value in order to avoid CookieOverflow.
  #
  # @param [Hash]    h
  # @param [Integer] max              Maximum size of representation.
  # @param [Integer] p_max            Max representation of individual param.
  #
  # @return [Hash{String=>any,nil}]
  #
  def abbreviate_params!(h, max: MAX_LAST_OP_PARAMS, p_max: MAX_LAST_OP_PARAM)
    k_chars = 6 # extra characters for JSON key representation ('"" => ')
    v_chars = 4 # extra characters for JSON value representation ('"", ')
    h_chars = 2 # extra characters for JSON hash representation ('{}')
    result  = h.extract!(*LAST_OP_NO_ABBREV).stringify_keys!
    size    = escaped_value(result).size
    h.transform_keys! { abbreviate_param(_1, p_max: (p_max - k_chars)) }
    while (size - h_chars + escaped_value(h).size) > max do
      h.transform_values! { abbreviate_param(_1, p_max: (p_max - v_chars)) }
      break unless (p_max /= 2) > v_chars
    end
    h.each_pair do |k, v|
      size += [k, v].sum { escaped_value(_1).size } + k_chars + v_chars
      return result.merge!('...' => '...') if size > max
      result.merge!(k => v)
    end
    result
  end

  # Generate an abbreviated representation of a value for diagnostics.
  #
  # @param [any, nil] item
  # @param [Integer]  p_max           Maximum size of representation.
  #
  # @return [any, nil]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def abbreviate_param(item, p_max: MAX_LAST_OP_PARAM)
    item = item.to_s if item.is_a?(Symbol)
    case item
      when nil, Numeric, BoolType, HASH_PLACEHOLDER, ARRAY_PLACEHOLDER
        item
      when Hash
        (escaped_value(item).size <= p_max) ? item : HASH_PLACEHOLDER
      when Array
        (escaped_value(item).size <= p_max) ? item : ARRAY_PLACEHOLDER
      when String
        e = escaped_value(item)
        (e.size <= p_max) ? item : item.truncate(p_max - (e.size - item.size))
      else
        '<%s>' % item.class.name
    end
  end

  # The item as it will be represented in the session cookie.
  #
  # @param [String, Symbol, Hash, Array] item
  #
  # @return [String]
  #
  def escaped_value(item)
    result = item.is_a?(Symbol) ? item.to_s : item
    result = result.to_json unless result.is_a?(String)
    # noinspection RubyMismatchedArgumentType
    Rack::Utils.escape(result)
  end

  # ===========================================================================
  # :section: Exception handlers
  # ===========================================================================

  public

  # Respond to ActionController::InvalidAuthenticityToken.
  #
  # @param [ActionController::InvalidAuthenticityToken] exception
  #
  # @return [nil]                     If not handled.
  # @return [any, nil]                Otherwise.
  #
  def session_expired_handler(exception)
    __debug_exception('[session expired] RESCUE_FROM', exception)
    msg = [config_term(:session, :expired)]
    msg << exception.message unless exception.message == exception.class.name
    msg = msg.compact_blank.join(' - ')
    respond_to do |format|
      format.html { redirect_to(root_path, alert: msg) }
      format.json { render_json({ error: msg }, status: :unauthorized) }
      format.xml  { render_xml({ error: msg }, status: :unauthorized) }
    end
  rescue => error
    error_handler_deep_fallback(__method__, error)
  end

  # Respond to the situation in which an authenticated user attempted to access
  # a route that is not allowed by the user's role.
  #
  # @param [CanCan::AccessDenied] exception
  #
  # @return [nil]                     If not handled.
  # @return [any, nil]                Otherwise.
  #
  def access_denied_handler(exception)
    __debug_exception('[access denied] RESCUE_FROM', exception)
    msg = exception.message
    respond_to do |format|
      format.html { redirect_back_or_to(root_path, alert: msg) }
      format.json { render_json({ error: msg }, status: :unauthorized) }
      format.xml  { render_xml({ error: msg }, status: :unauthorized) }
    end
  rescue => error
    error_handler_deep_fallback(__method__, error)
  end

  # Respond to page failures due to a failure to communicate with a remote
  # service.
  #
  # @param [ExecError, Faraday::Error] exception
  #
  # @return [nil]                     If not handled.
  # @return [any, nil]                Otherwise.
  #
  def connection_error_handler(exception)
    __debug_exception('[conn error] RESCUE_FROM', exception)
    self.status = :gateway_timeout
    if rendering_html?
      flash_now_alert(exception)
      render
    end
  rescue => error
    error_handler_deep_fallback(__method__, error)
  end

  # Respond to general page failures.
  #
  # @param [Exception] exception
  #
  # @return [nil]                     If not handled.
  # @return [any, nil]                Otherwise.
  #
  def fallback_error_handler(exception)
    __debug_exception('[fallback] RESCUE_FROM', exception, trace: true)
    self.status = :not_found
    if posting_html?
      redirect_back_or_to(root_path, alert: exception.message)
    elsif rendering_html?
      flash_now_alert(exception)
      render
    elsif rendering_json?
      render json: { ERROR: exception.message }
    elsif rendering_xml?
      render xml: make_xml({ ERROR: exception.message })
    end
  rescue => error
    error_handler_deep_fallback(__method__, error)
  end

  # ===========================================================================
  # :section: Exception handlers
  # ===========================================================================

  protected

  # If there is an error in the error handler it's probably due to a missing
  # template, so this method renders a safe page so that flash messages can
  # be displayed.
  #
  # @param [Symbol]    meth           Failed error handler.
  # @param [Exception] error
  #
  def error_handler_deep_fallback(meth, error = nil)
    Log.error { "#{meth} FAILED: #{error.inspect}" } if error
    self.status = :internal_server_error
    render welcome_path
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
    return if (params[:controller] == 'search') && (params[:action] == 'image')
    session_keys.each do |key|
      value = session[key]
      session.delete(key) if value.try(:empty?) || value.nil?
    end
  end

  # If a reboot occurred since the last session update, ensure consistency by
  # performing a sign-out and cleaning up related session data.
  #
  # @return [void]
  #
  # === Usage Notes
  # This must be invoked as a :before_action.
  #
  def session_check
    return if (t_last = last_operation_time).zero?
    return if (t_boot = BOOT_TIME.to_i) < t_last
    __debug  { "last_operation_time #{t_last} < BOOT_TIME #{t_boot}" }
    Log.info { "Signed out #{current_user&.to_s || 'user'} after reboot." }
    local_sign_out
  end

  # Remember the last operation performed in this session and set the flash
  # alert if there was an unprocessed ApiSession exception.
  #
  # @raise [Exception]                Propagated if raised by the block.
  #
  # === Usage Notes
  # This must be invoked as an :around_action.
  #
  # === Implementation Notes
  # The "ensure" block is executed before the ApplicationController
  # "rescue_from".  However, note that Rails is doing something with "$!" which
  # causes Faraday::ClientError to be the exception that's acted upon in that
  # block, whereas :api_error_message shows the ApiService::Error that is
  # created in ApiService::Common#api.
  #
  #--
  # noinspection RubyMismatchedArgumentType
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

  rescue ActionController::InvalidAuthenticityToken => error
    error = nil if session_expired_handler(error)

  rescue => error
    __debug_exception('UNHANDLED EXCEPTION', error, trace: true)
    flash_now_alert(api_exec_report, html: true) if api_error?

  ensure
    api_reset
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
      #--
      # noinspection RbsMissingTypeSignature
      #++
      def require_no_authentication
        super
        flash_message = session.delete('app.devise.failure.message')
        flash_alert(flash_message, clear: true) if flash_message
      end

    end

  end

end

__loading_end(__FILE__)
