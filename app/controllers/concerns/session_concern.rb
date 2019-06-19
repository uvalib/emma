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
    session[:current_path].presence || super(resource_or_scope)
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
  # @param [String, nil] params       Default: `#url_parameters`.
  #
  # @return [Hash]
  #
  def last_operation_update(hash = nil, time: nil, path: nil, params: nil)
    values = {
      time:   time&.to_i || Time.now.to_i,
      path:   path       || request.path,
      params: params     || url_parameters
    }
    values.merge(hash) if hash.present?
    last_operation.merge!(values.stringify_keys)
      .tap {
        __debug { "session_update 'time' = #{last_operation_time.inspect}" }
      }
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Clean out-dated session information between reboots.
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

  # Remember the last operation performed in this session.
  #
  # == Usage Notes
  # This must be invoked as an :around_action.
  #
  def session_update
    yield.tap do
      error = defined?(@api) && @api&.exception
      error &&= error.message.presence || I18n.t('emma.error.api.unknown')
      flash[:alert] = error if error
      last_operation_update
    end
  end

end

__loading_end(__FILE__)
