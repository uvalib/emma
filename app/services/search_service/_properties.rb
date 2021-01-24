# app/services/search_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Properties
#
module SearchService::Properties

  # @private
  def self.included(base)
    base.send(:extend, self)
  end

  include ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values from config/locales/service.en.yml
  #
  # @type [Hash{Symbol=>*}]
  #
  SEARCH_CONFIG = i18n_erb('emma.service.search').deep_freeze

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  # @see #SEARCH_BASE_URL
  #
  def base_url
    @base_url ||= SEARCH_BASE_URL
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

end

__loading_end(__FILE__)
