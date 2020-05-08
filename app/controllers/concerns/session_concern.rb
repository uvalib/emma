# app/controllers/concerns/session_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SessionConcern
#
module SessionConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'SessionConcern')

    # Non-functional hints for RubyMine.
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
        flash.now[:alert] ||= exception.message
        render layout: layout
      end
    end

  end

  include Emma::Debug
  include ParamsConcern
  include ApiConcern

  # Non-functional hints for RubyMine.
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
  # This method overrides:
  # @see Devise::Controllers::Helpers#after_sign_in_path_for
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
  # This method overrides:
  # @see Devise::Controllers::Helpers#after_sign_out_path_for
  #
  def after_sign_out_path_for(*)
    welcome_path
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
  # @param [Hash]   req_params        Default: `#params`.
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
    sign_out
    session.delete('omniauth.auth')
    @reset_browser_cache = true
  end

  # Remember the last operation performed in this session and set the flash
  # alert if there was an unprocessed ApiSession exception.
  #
  # == Usage Notes
  # This must be invoked as an :around_action.
  #
  # == Implementation Notes
  # The "ensure" block is executed before the ApplicationController
  # "rescue_from".  However, note that Rails is doing something with "$!" which
  # causes Faraday::ClientError to be the exception that's acted upon in that
  # block, whereas :api_error_message shows the BookshareService::ResponseError
  # that is created in BookshareService::Common#api.
  #
  def session_update
    error = nil
    yield

  rescue => error
    __debug_exception('UNHANDLED EXCEPTION', error)
    flash.now[:alert] ||= api_error_message if api_error?

  ensure
    last_operation_update
    raise error if error
  end

end

__loading_end(__FILE__)
