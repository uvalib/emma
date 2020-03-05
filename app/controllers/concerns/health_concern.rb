# app/controllers/concerns/health_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HealthConcern
#
module HealthConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'HealthConcern')
  end

  include Emma::Time

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Locale entries for this controller.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see config/locales/controllers/health.en.yml
  #
  # noinspection RailsI18nInspection
  HEALTH_18N_ENTRIES =
    I18n.t('emma.health').select { |_, v| v.is_a?(Hash) }.deep_freeze

  # Default health check subsystem failure message.
  #
  # @type [String]
  #
  DEFAULT_HEALTH_FAILED_MESSAGE = HEALTH_18N_ENTRIES.dig(:default, :failed)

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
    # == Health check methods
    # *nil*     The implied health check method is used.
    # *true*    The subsystem is always reported as healthy.
    # *false*   The subsystem is always reported as failed.
    #
    # == Restart
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

    # @return [String]
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
      health.values.all?(&:healthy?)
    end

    def failed?
      health.values.all?(&:failed?)
    end

    def degraded?
      v = health.values
      v.any?(&:degraded?) || (v.select(&:healthy?).size < health.size)
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
    HEALTH_18N_ENTRIES.map { |subsystem, items|
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
  INVALID_HEALTH_CHECK = HealthEntry.new(**HEALTH_18N_ENTRIES[:invalid]).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the health status of one or more subsystems.
  #
  # @param [Array<String|Symbol>] subsystem   Default: `HEALTH_CHECK.keys`
  #
  # @return [Hash{Symbol=>HealthStatus}]
  #
  # @see #HEALTH_CHECK
  #
  def get_health_status(*subsystem)
    subsystem = subsystem.flatten.reject(&:blank?).map(&:to_sym).presence
    entries   = subsystem&.map { |ss| [ss, nil] }&.to_h || HEALTH_CHECK
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
  # noinspection RubyScope, RubyUnusedLocalVariable
  def status_report(subsystem, entry = nil)
    entry ||= HEALTH_CHECK[subsystem] || INVALID_HEALTH_CHECK
    method  = entry[:method]
    message = nil
    start   = timestamp
    healthy =
      case method
        when Proc       then method.call
        when Symbol     then send(method)
        when FalseClass then false
        else                 true
      end

  rescue => e
    healthy = false
    message = "#{e.class}: #{e.message}"
    Log.warn { "#{subsystem}: #{message}" }

  ensure
    warn_only = !entry[:restart]
    degraded  = !healthy && warn_only
    message   = degraded && entry[:degraded]
    message ||= healthy ? entry[:healthy] : entry[:failed]
    message ||= time_span(start)
    healthy   = true if warn_only
    return HealthStatus.new(healthy, degraded, message)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Health status of the MySQL service.
  #
  # @return [Boolean]
  #
  def mysql_status(*)
    ActiveRecord::Base.connection_pool.with_connection(&:active?)
  end

  # Health status of the Redis service.
  #
  # @return [Boolean]
  #
  def redis_status(*)
    true # TODO: future
  end

  # Health status of the Unified Search service.
  #
  # @return [Boolean]
  #
  def search_status(*)
    SearchService.active?
  end

  # Health status of the Bookshare API service.
  #
  # @return [Boolean]
  #
  def bookshare_status(*)
    BookshareService.active?
  end

  # Health status of the ingest service.
  #
  # @return [Boolean]
  #
  def ingest_status(*)
    true # TODO: future
  end

end

__loading_end(__FILE__)
