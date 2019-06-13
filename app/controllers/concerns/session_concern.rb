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
  end

  include ParamsConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

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
      last_operation_update
      __debug { "#{__method__} 'time' = #{last_operation_time.inspect}" }
    end
  end

end

__loading_end(__FILE__)
