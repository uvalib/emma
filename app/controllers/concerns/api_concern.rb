# app/controllers/concerns/api_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for any API service(s) that have been activated.
#
module ApiConcern

  extend ActiveSupport::Concern

  include SessionDebugHelper

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
  def api_service(service, **opt)
    opt[:user] = current_user  unless opt.key?(:user)
    service    = service.class unless service.is_a?(Class)
    service.instance(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Remove all active API service(s).
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  # @param [Hash]         opt         Passed to #api_active_table.
  #
  # @return [void]
  #
  def api_clear(*only, **opt)
    opt[:user] = current_user unless opt.key?(:user)
    if only.present?
      ApiService.table(**opt).except!(*only)
    else
      ApiService.clear(**opt)
    end
  end

  # Indicate whether any API request generated an exception.
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  # @param [Hash]         opt         Passed to #api_active_table.
  #
  def api_error?(*only, **opt)
    api_active_table(*only, **opt).values.any?(&:error?)
  end

  # Get the current API exception message(s).
  #
  # @param [Array<Class>] only          If given, limit to those service(s).
  # @param [Hash]         opt           Passed to #api_active_table.
  #
  # @return [Hash{Class=>ExecReport}]   Multiple services with error messages.
  # @return [ExecReport]                Current service error message.
  # @return [nil]                       No service error or service not active.
  #
  def api_exec_report(*only, **opt)
    table = api_active_table(*only, **opt).transform_values(&:exec_report)
    table.compact!
    (table.size == 1) ? table.values.first : table.presence
  end

  # Get the current API service exception.
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  # @param [Hash]         opt         Passed to #api_active_table.
  #
  # @return [Hash{Class=>Exception}]  Multiple services with exceptions.
  # @return [Exception]               Current service exception.
  # @return [nil]                     No exception or service not active.
  #
  def api_exception(*only, **opt)
    table = api_active_table(*only, **opt).transform_values(&:exception)
    table.compact!
    (table.size == 1) ? table.values.first : table.presence
  end

  # Clear the current API service exception.
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  # @param [Hash]         opt         Passed to #api_active_table.
  #
  # @return [void]
  #
  def api_reset(*only, **opt)
    api_active_table(*only, **opt).values.each(&:clear_error)
  end

  # The ApiService.table with any blank entries removed.
  #
  # @param [Array<Class>] only        If given, limit to those service(s).
  # @param [Hash]         opt         Passed to ApiService#table.
  #
  # @return [Hash{Class=>ApiService}]
  #
  def api_active_table(*only, **opt)
    opt[:user] = current_user unless opt.key?(:user)
    ApiService.table(**opt).select do |service, instance|
      instance.present? && (only.blank? || only.include?(service))
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Modify :emma_data fields and content.
  #
  # @param [String, Integer, nil] api_version
  # @param [Hash]                 opt
  #
  # @option [String, Integer] :version  If *api_version* is not given.
  # @option [String, Integer] :v        Alias for :version
  # @option [String, Boolean] :verbose  If *true*, generate log output.
  # @option [String, Boolean] :report   If *false*, do not generate report.
  # @option [String, Boolean] :dryrun   If *false*, actually update database.
  #
  # @return [Hash]
  # @return [nil]                       If no API version was specified.
  #
  # @see ApiMigrate#initialize
  # @see ApiMigrate#run!
  #
  # === Usage Notes
  # The default mode is to perform a dry run, so :dryrun must be explicitly
  # passed in as *false* to actually modify the database table.
  #
  def api_data_migration(api_version = nil, **opt)
    version = api_version || opt[:v] || opt[:version] or return
    dryrun  = !false?(opt[:dryrun])
    raise "#{__method__}: developer-only option" unless dryrun || developer?
    verbose = opt.key?(:verbose) ? true?(opt[:verbose]) : session_debug?
    report  = !false?(opt[:report])
    migrate = ApiMigrate.new(version, report: report, log: verbose)
    records = migrate.run!(update: !dryrun)
    { count: records.size }.merge!(migrate.report || {})
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

__loading_end(__FILE__)
