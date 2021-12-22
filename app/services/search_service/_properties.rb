# app/services/search_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Properties
#
module SearchService::Properties

  include ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values from config/locales/service.en.yml
  #
  # @type [Hash{Symbol=>Any}]
  #
  SEARCH_CONFIG = i18n_erb('emma.service.search').deep_freeze

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

  # An API key is not a part of search URLs.
  #
  # @return [nil]
  #
  def api_key
    nil
  end

  # API version is not a part of search URLs.
  #
  # @return [nil]
  #
  def api_version
    # SEARCH_API_VERSION
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
    SEARCH_CONFIG[:endpoint]
  end

  # Default search engine for this deployment.
  #
  # @return [String]
  #
  def default_engine_url
    SEARCH_BASE_URL || engines[DEFAULT_ENGINE]
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
