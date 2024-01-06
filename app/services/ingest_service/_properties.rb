# app/services/ingest_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IngestService::Properties
#
module IngestService::Properties

  include ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values from config/locales/service.en.yml
  #
  # @type [Hash{Symbol=>*}]
  #
  CONFIGURATION = i18n_config('emma.service.ingest').deep_freeze

  # Default engine selection.
  #
  # @type [Symbol]
  #
  DEFAULT_ENGINE = production_deployment? ? :production : :staging

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # Configuration for the EMMA Unified Ingest service.
  #
  # @type [Hash{Symbol=>*}]
  #
  def configuration
    CONFIGURATION
  end

  # EMMA Unified Ingest API key.
  #
  # @return [String, nil]
  #
  # @see #INGEST_API_KEY
  #
  def api_key
    INGEST_API_KEY || super
  end

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # Default ingest engine for this deployment.
  #
  # @return [String]
  #
  def default_engine_url
    INGEST_BASE_URL || super
  end

  # The default ingest engine API key.
  #
  # @return [Symbol]
  #
  def default_engine_key
    DEFAULT_ENGINE || super
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
