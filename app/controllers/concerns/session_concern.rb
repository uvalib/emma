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
    include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # =========================================================================
    # :section: Session management
    # =========================================================================

    prepend_before_action :session_check,  unless: :devise_controller?
    before_action         :cleanup_session
    append_around_action  :session_update, unless: :devise_controller?

  end

  include ApiHelper
  include ParamsHelper

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
  # @type [Array<String,Regexp>]
  #
  IGNORE_SESSION_KEYS = [
    'flash',
    'session_id',
    '_csrf_token',
    '_turbolinks_location',
    /\./,
    /_return_to$/,
  ].freeze

  # Default API error message
  #
  # @type [String]
  #
  UNKNOWN_API_ERROR = I18n.t('emma.error.api.unknown').freeze

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
  def after_sign_in_path_for(resource_or_scope)
    store_location_for(resource_or_scope, dashboard_path)
    path = session['current_path']
    path = nil if path == welcome_path
    path || super(resource_or_scope)
  end

  # after_sign_in_path_for
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
  # @param [Hash, nil] hash
  # @param [Time]      time           Default: `Time.now`.
  # @param [String]    path           Default: `request.path`.
  # @param [Hash]      req_params     Default: `#request_parameters`.
  #
  # @return [Hash]
  #
  def last_operation_update(hash = nil, time: nil, path: nil, req_params: nil)
    req_params ||= request_parameters
    # noinspection RubyCaseWithoutElseBlockInspection
    case req_params[:controller]
      when 'api' then return if req_params[:action] == 'image'
    end
    values = {
      time:   (time || Time.now).to_i,
      path:   (path || request.path),
      params: url_parameters(req_params)
    }
    values.merge!(hash) if hash.present?
    last_operation.merge!(values.stringify_keys)
      .tap {
        __debug { "session_update 'time' = #{last_operation_time.inspect}" }
      }
  end

  # Application-specific `#session` keys.
  #
  # @return [Array<String>]
  #
  def session_keys
    session.keys.reject do |key|
      IGNORE_SESSION_KEYS.any? do |ignore_key|
        ignore_key.is_a?(Regexp) ? key.match?(ignore_key) : (key == ignore_key)
      end
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
    return if (t_boot = BOOT_TIME.to_i) < (t_last = last_operation_time)
    if t_last.nonzero?
      Log.info { "Signed out #{current_user&.to_s || 'user'} after reboot." }
      __debug { "last_operation_time #{t_last} < BOOT_TIME #{t_boot}" }
    end
    sign_out
    session.delete('omniauth.auth')
    @reset_browser_cache = true
  end

  # Remember the last operation performed in this session and set the flash
  # alert if there is an unprocessed ApiSession exception.
  #
  # == Usage Notes
  # This must be invoked as an :around_action.
  #
  def session_update
    yield.tap do
      if (exception = api_exception)
        flash.now[:alert] = exception.message.presence || UNKNOWN_API_ERROR
      end
      last_operation_update
    end
  end

end

__loading_end(__FILE__)
