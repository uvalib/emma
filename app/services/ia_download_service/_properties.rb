# app/services/ia_download_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IaDownloadService::Properties
#
module IaDownloadService::Properties

  include ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values from "config/locales/service.en.yml".
  #
  # @type [Hash]
  #
  CONFIGURATION = config_section(:service, :ia_download).deep_freeze

  # Authorization header for IA download requests.
  #
  # @type [String]
  #
  # @see https://archive.org/services/docs/api/ias3.html#skip-request-signing
  # @see https://archive.org/account/s3.php
  #
  IA_AUTH = "LOW #{IA_ACCESS}:#{IA_SECRET}"

  # Headers needed to authenticate with the IA server.
  #
  # @type [Hash{String=>String}]
  #
  IA_HEADERS = {
    Authorization: IA_AUTH,
  }.stringify_keys.deep_freeze

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # Configuration for the API service.
  #
  # @return [Hash]
  #
  def configuration
    CONFIGURATION
  end

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # Maximum length of redirection chain.
  #
  # @type [Integer]
  #
  def max_redirects
    MAX_REDIRECTS
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
