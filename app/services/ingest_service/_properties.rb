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
  # @type [Hash{Symbol=>Any}]
  #
  INGEST_CONFIG = i18n_erb('emma.service.ingest').deep_freeze

  # Valid ingest endpoint URLs.
  #
  # @type [Hash{Symbol=>String}]
  #
  INGEST_ENGINES = INGEST_CONFIG[:endpoint]

  # Default engine selection.
  #
  # @type [Symbol]
  #
  DEFAULT_ENGINE = (application_deployment == :staging) ? :staging : :staging     # TODO: remove
  #DEFAULT_ENGINE = (application_deployment == :staging) ? :staging : :production  # TODO: uncomment

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  # @see #default_engine_url
  #
  def base_url
    @base_url ||= default_engine_url
  end

  # Federated Ingest API key.
  #
  # @return [String]
  #
  # @see #INGEST_API_KEY
  #
  def api_key
    INGEST_API_KEY
  end

  # API version is not a part of request URLs.
  #
  # @return [nil]
  #
  def api_version
    # INGEST_API_VERSION
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Valid search engine URLs.
  #
  # @type [Hash{Symbol=>String}]
  #
  def engines
    INGEST_CONFIG[:endpoint]
  end

  # Default search engine for this deployment.
  #
  # @return [String]
  #
  def default_engine_url
    INGEST_BASE_URL || engines[DEFAULT_ENGINE]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
