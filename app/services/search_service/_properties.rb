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
  # @type [Hash{Symbol=>*}]
  #
  CONFIGURATION = config_section('emma.service.search').deep_freeze

  # Default engine selection.
  #
  # @type [Symbol]
  #
  DEFAULT_ENGINE = production_deployment? ? :production : :staging

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # Configuration for the API service.
  #
  # @type [Hash{Symbol=>*}]
  #
  def configuration
    CONFIGURATION
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default search engine for this deployment.
  #
  # @return [String]
  #
  def default_engine_url
    SEARCH_BASE_URL || super
  end

  # The default service engine key.
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
