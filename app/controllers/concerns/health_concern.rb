# app/controllers/concerns/health_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HealthConcern
#
module HealthConcern

  extend ActiveSupport::Concern

  include TimeHelper

  included do |base|
    __included(base, 'HealthConcern')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Subsystem health check properties.
  #
  class HealthEntry < Hash

    include ParamsHelper

    # Initialize a new instance.
    #
    # @param [Hash, nil]                  hash      Another hash, if provided.
    # @param [Symbol, Proc, String, nil]  method    Health check method:
    #                                               - *nil*: the implied health
    #                                                 check method is used.
    #                                               - *true*: the subsystem is
    #                                                 always reported healthy.
    #                                               - *false*: the subsystem is
    #                                                 always reported failed.
    # @param [Boolean, nil] restart                 If *true*, a failed health
    #                                                 check should result in a
    #                                                 system restart in order
    #                                                 to attempt to correct the
    #                                                 underlying problem.
    # @param [String, nil] healthy                  Message if healthy.
    # @param [String, nil] degraded                 Message if degraded.
    # @param [String, nil] failed                   Message if failed.
    #
    def initialize(
      hash =    nil,
      method:   nil,
      restart:  nil,
      healthy:  nil,
      degraded: nil,
      failed:   nil
    )
      if hash.is_a?(Hash)
        method   ||= hash[:method]
        restart  ||= hash[:restart]
        healthy  ||= hash[:healthy]
        degraded ||= hash[:degraded]
        failed   ||= hash[:failed]
      end
      replace(
        method:   method,
        restart:  true?(restart),
        healthy:  healthy,
        degraded: degraded,
        failed:   failed
      )
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
      @message  = message || (@healthy ? '' : 'Unknown error')
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
  # @see en.emma.health in config/locales/en.yml
  #
  HEALTH_CHECK =
    I18n.t('emma.health').map { |subsystem, items|
      entry = HealthEntry.new(items)
      entry[:method] ||= "#{subsystem}_status".to_sym
      entry[:failed] ||= 'Unknown error'
      [subsystem, entry.freeze]
    }.to_h.freeze

  # Used for checks of subsystems that don't exist.
  #
  # @type [Hash{Symbol=>Object}]
  #
  INVALID_HEALTH_CHECK =
    HealthEntry.new(method: false, failed: 'NOT A VALID SUBSYSTEM').freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the health status of one or more subsystems.
  #
  # @param [Array<String|Symbol>] subsystem   Default: `HEALTH_CHECK.keys`
  #
  # @return [Hash]
  #
  # @see #HEALTH_CHECK
  #
  def get_health_status(*subsystem)
    subsystem.map!(&:to_sym).reject!(&:blank?)
    entries = subsystem.map { |ss| [ss, nil] }.to_h.presence || HEALTH_CHECK
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
  # @param [Symbol]    subsystem
  # @param [Hash, nil] entry
  #
  # @return [HealthStatus]
  #
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

  # Health status of the Bookshare API service.
  #
  # @return [Boolean]
  #
  def bookshare_status(*)
    ApiService.instance(false).get_title_count.to_i > 0
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
