# app/services/lookup_service/_remote_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LookupService::RemoteService::Properties
#
module LookupService::RemoteService::Properties

  include ApiService::Properties

  include LookupService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # How important an external service is as an authority for the type(s) of
  # identifiers it can search.  For example:
  #
  # * 1   High
  # * 10  Medium
  # * 100 Low
  #
  # @type [Integer]
  #
  # @see LookupService#service_table
  #
  DEFAULT_PRIORITY = CONFIGURATION.dig(:_template, :priority)

  # How long to wait for a response from the external service.
  #
  # @type [Float]
  #
  DEFAULT_TIMEOUT = CONFIGURATION.dig(:_template, :timeout)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The configuration key for the service.
  #
  # @return [Symbol]
  #
  def service_key
    (is_a?(Module) ? name : self.class.name).demodulize.underscore.to_sym
  end

  # Indicate whether requests are enabled to this external service.
  #
  # @return [Boolean]
  #
  def enabled
    !false?(configuration[:enabled])
  end

  alias :enabled? :enabled

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # Configuration for the API service.
  #
  # @return [Hash]
  #
  def configuration
    CONFIGURATION[service_key]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Types of identifiers that the external service can find.
  #
  # @return [Array<Symbol>]
  #
  def types
    configuration[:types]
  end

  # How important the external service is as an authority for the type(s) of
  # identifiers it can search.
  #
  # @type [Integer]
  #
  def priority
    configuration[:priority] || DEFAULT_PRIORITY
  end

  # How long to wait for a response from the external service.
  #
  # @return [Float]
  #
  def timeout
    configuration[:timeout] || DEFAULT_TIMEOUT
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
