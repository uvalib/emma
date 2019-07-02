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

    include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION

    # =========================================================================
    # :section: Session management
    # =========================================================================

    prepend_before_action :session_check,  unless: :devise_controller?
    append_around_action  :session_update, unless: :devise_controller?

  end

  include ParamsHelper

  include Devise::Controllers::Helpers unless ONLY_FOR_DOCUMENTATION

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
    path = session[:current_path]
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
    session['last_op'] = {} unless session['last_op']
    session['last_op']
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
  # @param [Hash, nil]   hash
  # @param [Time, nil]   time         Default: `Time.now`.
  # @param [String, nil] path         Default: `request.path`.
  # @param [Hash, nil]   url_params   Default: `#url_parameters`.
  #
  # @return [Hash]
  #
  def last_operation_update(hash = nil, time: nil, path: nil, url_params: nil)
    url_params ||= params.to_unsafe_h
    case url_params[:controller]
      when 'api' then return if url_params[:action] == 'image'
    end
    values = {
      time:   (time || Time.now).to_i,
      path:   (path || request.path),
      params: url_params.except!(*IGNORED_PARAMETERS)
    }
    values.merge!(hash) if hash.present?
    last_operation.merge!(values.stringify_keys)
      .tap {
        __debug { "session_update 'time' = #{last_operation_time.inspect}" }
      }
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Clean out-dated session information.
  #
  # If a reboot occurred since the last session update, ensure consistency by
  # performing a sign-out and cleaning up related session data.
  #
  # @return [void]
  #
  # == Usage Notes
  # This must be invoked as a :before_action.
  #
  def session_check

    # Clean out empty session values.
    session.keys.each do |key|
      value = session[key]
      session.delete(key) if value.nil? || (value.is_a?(Hash) && value.empty?)
    end

    # Reset authentication state after a reboot.
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
      error = defined?(@api) && @api&.exception
      error &&= error.message.presence || I18n.t('emma.error.api.unknown')
      flash.now[:alert] = error if error
      last_operation_update
    end
  end

end

__loading_end(__FILE__)
