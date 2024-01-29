# app/controllers/concerns/health_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/health" controller.
#
module HealthConcern

  extend ActiveSupport::Concern

  include Emma::TimeMethods
  include Emma::Debug

  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Locale entries for this controller.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see file:config/locales/controllers/health.en.yml
  #
  HEALTH_SUBSYSTEMS = config_section('emma.health.subsystem').deep_freeze

  # Default health check subsystem failure message.
  #
  # @type [String]
  #
  DEFAULT_HEALTH_FAILED_MESSAGE = HEALTH_SUBSYSTEMS.dig(:default, :failed)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Subsystem health check properties.
  #
  class HealthEntry < Hash

    include Emma::Common

    # Initialize a new instance.
    #
    # @param [Symbol, Proc, String] method    Health check method (see below).
    # @param [Boolean]              restart   See below.
    # @param [String]               healthy   Message if healthy.
    # @param [String]               degraded  Message if degraded.
    # @param [String]               failed    Message if failed.
    #
    # === Health check methods
    # *nil*     The implied health check method is used.
    # *true*    The subsystem is always reported as healthy.
    # *false*   The subsystem is always reported as failed.
    #
    # === Restart
    # If :restart is *true* then a failed health check should result in a
    # system restart in order to attempt to correct the underlying problem.
    #
    def initialize(
      method:   nil,
      restart:  nil,
      healthy:  nil,
      degraded: nil,
      failed:   nil
    )
      self[:method]   = method
      self[:restart]  = true?(restart)
      self[:healthy]  = healthy
      self[:degraded] = degraded
      self[:failed]   = failed
    end

  end

  # The basic health status report object.
  #
  class HealthStatus

    # @return [Boolean]
    attr_accessor :healthy

    # @return [Boolean]
    attr_accessor :degraded

    # @return [String, nil]
    attr_accessor :message

    def initialize(status, degraded, message = nil)
      @healthy  = status.present?
      @degraded = degraded.present?
      @message  = message
      @message  = DEFAULT_HEALTH_FAILED_MESSAGE unless message || @healthy
    end

    def healthy?
      @healthy
    end

    def failed?
      !healthy?
    end

    def degraded?
      @degraded
    end

  end

  # The health check response.
  #
  class HealthResponse

    # @return [Hash{Symbol=>HealthStatus}]
    attr_reader :health

    def initialize(status_values = nil)
      @health = status_values || {}
    end

    def healthy?
      v = health.values
      v.blank? || v.all?(&:healthy?)
    end

    def failed?
      v = health.values
      v.present? && v.all?(&:failed?)
    end

    def degraded?
      v = health.values
      v.any?(&:degraded?) || v.any?(&:failed?)
    end

    delegate_missing_to :health

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Subsystems to monitor for health status.
  #
  # @type [Hash{Symbol=>HealthEntry}]
  #
  HEALTH_CHECK =
    HEALTH_SUBSYSTEMS.map { |subsystem, items|
      next if %i[default invalid].include?(subsystem)
      entry = HealthEntry.new(**items)
      entry[:method] = "#{subsystem}_status".to_sym if entry[:method].nil?
      entry[:failed] ||= DEFAULT_HEALTH_FAILED_MESSAGE
      [subsystem, entry]
    }.compact.to_h.deep_freeze

  # Used for checks of subsystems that don't exist.
  #
  # @type [HealthEntry]
  #
  INVALID_HEALTH_CHECK = HealthEntry.new(**HEALTH_SUBSYSTEMS[:invalid]).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The value of `params[:subsystem]`, which may be one or more comma-separated
  # subsystem names.
  #
  # @return [Array<String>]
  #
  def subsystems
    @subsystems ||= params[:subsystem].to_s.remove(/\s/).split(',')
  end

  # Acquire build version and render as JSON.
  #
  def render_version
    render json: { version: BUILD_VERSION }, status: 200
  end

  # Acquire health status and render as JSON.
  #
  def render_check
    values   = get_health_status(*subsystems)
    response = HealthResponse.new(values)
    status   = response.failed? ? 500 : 200
    render json: response, status: status
  end

  # Get the health status of one or more subsystems.
  #
  # @param [Array<String,Symbol>] subsystem   Default: `HEALTH_CHECK.keys`
  #
  # @return [Hash{Symbol=>HealthStatus}]
  #
  # @see #HEALTH_CHECK
  #
  def get_health_status(*subsystem)
    subsystem = subsystem.flatten.compact_blank!.map!(&:to_sym).presence
    entries   = subsystem&.map! { |ss| [ss, nil] }&.to_h || HEALTH_CHECK
    entries.map { |type, entry| [type, status_report(type, entry)] }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Run a health check method to report on the status of a subsystem.
  #
  # If *entry* does not have an explicit :healthy message then the time taken
  # for the check is displayed.
  #
  # @param [Symbol]           subsystem
  # @param [HealthEntry, nil] entry
  #
  # @return [HealthStatus]
  #
  #--
  # noinspection RubyScope, RubyMismatchedArgumentType
  #++
  def status_report(subsystem, entry = nil)
    entry ||= HEALTH_CHECK[subsystem] || INVALID_HEALTH_CHECK
    lockout = RunState.unavailable?
    meth    = (entry[:method] unless lockout)
    start   = timestamp
    healthy, message =
      case meth
        when Proc       then meth.call
        when Symbol     then send(meth)
        when FalseClass then false
        else                 !lockout
      end
  rescue => error
    healthy = false
    message = "#{error.class}: #{error.message}"
    Log.warn { "#{subsystem}: #{message}" }
  ensure
    warn_only = !entry[:restart] || lockout
    degraded  = !healthy && warn_only
    message ||= lockout  && config_text(:health, :unavailable)
    message ||= degraded && entry[:degraded]
    message ||= healthy ? entry[:healthy] : entry[:failed]
    message ||= time_span(start)
    healthy   = true if warn_only
    return HealthStatus.new(healthy, degraded, message)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Health status of the database service.
  #
  # @return [Array<(Boolean,String)>]
  # @return [Array<(Boolean,nil)>]
  #
  def database_status(...)
    healthy = ActiveRecord::Base.connection_pool.with_connection(&:active?)
    message = nil # TODO: Database status message?
    return healthy, message
  end

  # Health status of the Redis service.
  #
  # @return [Array<(Boolean,String)>]
  # @return [Array<(Boolean,nil)>]
  #
  def redis_status(...)
    healthy = true # TODO: Redis health status
    message = nil  # TODO: Redis status message?
    return healthy, message
  end

  # Health status of AWS storage.
  #
  # @return [Array<(Boolean,String)>]
  # @return [Array<(Boolean,nil)>]
  #
  def storage_status(...)
    healthy = true # TODO: AWS health status
    message = nil  # TODO: AWS status message?
    return healthy, message
  end

  # Health status of the EMMA Unified Search service.
  #
  # @return [Array<(Boolean,String)>]
  # @return [Array<(Boolean,nil)>]
  #
  def search_status(...)
    SearchService.active_status
  end

  # Health status of the EMMA Unified Ingest service.
  #
  # @return [Array<(Boolean,String)>]
  # @return [Array<(Boolean,nil)>]
  #
  def ingest_status(...)
    IngestService.active_status
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the current RunState and setup the HTTP response accordingly.
  #
  # @return [RunState]
  #
  def show_run_state
    RunState.current.tap do |state|
      after = state.retry_value and response.set_header('Retry-After', after)
    end
  end

  # Restore system availability.
  #
  # @return [void]
  #
  # @note Currently unused.
  #
  # === Usage Notes
  # Does nothing unless RunState::CLEARABLE or RunState::DYNAMIC.
  #
  def clear_run_state
    if RunState::STATIC
      Log.warn { "#{__method__}: skipped (RunState::STATIC)" }
    else
      RunState.clear_current
    end
  end

  # Set the current RunState
  #
  # @param [Hash, String, nil] source   Ignored unless RunState::DYNAMIC.
  #
  # @return [void]
  #
  # === Usage Notes
  # Does nothing unless RunState::CLEARABLE or RunState::DYNAMIC.
  #
  def update_run_state(source = nil)
    if RunState::DYNAMIC
      RunState.set_current(source || url_parameters)
      warning = nil
    elsif RunState::CLEARABLE
      RunState.clear_current
      warning = source && 'parameters ignored (RunState::CLEARABLE)'
    else
      warning = 'skipped (RunState::STATIC)'
    end
    Log.warn { "#{__method__}: #{warning}" } if warning
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
