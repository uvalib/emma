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
  INGEST_CONFIG = i18n_erb('emma.service.ingest').deep_freeze

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  # @see #INGEST_BASE_URL
  #
  def base_url
    @base_url ||= INGEST_BASE_URL
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

  private

  def self.included(base)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
