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
  CONFIGURATION = i18n_erb('emma.service.search').deep_freeze

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

  # Configuration for the API service.
  #
  # @type [Hash{Symbol=>Any}]
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
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
