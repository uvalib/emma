# app/controllers/concerns/api_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for any API service(s) that have been activated.
#
module ApiConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'ApiConcern')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Find or create the instance of the requested service.
  #
  # @param [Class] service
  #
  # @return [ApiService]
  #
  def api_service(service)
    service = service.class unless service.is_a?(Class)
    ApiService.table[service] || api_update(service).values.first
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Update all active API service(s).
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  # @param [Hash]         opt
  #
  # @return [Hash{Class=>ApiService}]
  #
  def api_update(*only, **opt)
    opt[:user] = current_user if !opt.key?(:user) && current_user.present?
    opt[:no_raise] = true     if !opt.key?(:no_raise) && Rails.env.test?
    services = only.presence || api_active_table.keys
    services.each { |srv| srv.update(**opt) }
    api_active_table(*only)
  end

  # Remove all active API service(s).
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  #
  # @return [nil]
  #
  def api_clear(*only)
    api_active_table(*only).keys.each(&:clear) and nil
  end

  # Indicate whether any API service has been activated.
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  #
  def api_active?(*only)
    api_active_table(*only).present?
  end

  # Indicate whether any API request generated an exception.
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  #
  def api_error?(*only)
    api_active_table(*only).values.any?(&:error?)
  end

  # Get the current API exception message(s).
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  #
  # @return [Hash{Class=>String}]     Multiple services with error messages.
  # @return [String]                  Current service error message.
  # @return [nil]                     No service error or service not active.
  #
  def api_error_message(*only)
    table = api_active_table(*only).transform_values(&:error_message).compact
    # noinspection RubyYardReturnMatch
    (table.size == 1) ? table.values.first : table.presence
  end

  # Get the current Bookshare API exception.
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  #
  # @return [Hash{Class=>Exception}]  Multiple services with exceptions.
  # @return [Exception]               Current service exception.
  # @return [nil]                     No exception or service not active.
  #
  def api_exception(*only)
    table = api_active_table(*only).transform_values(&:exception).compact
    # noinspection RubyMismatchedReturnType
    (table.size == 1) ? table.values.first : table.presence
  end

  # The ApiService.table with any blank entries removed.
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  #
  # @return [Hash{Class=>ApiService}]
  #
  def api_active_table(*only)
    ApiService.table.compact.tap do |result|
      result.keep_if { |service, _| only.include?(service) } if only.present?
    end
  end

end

__loading_end(__FILE__)
