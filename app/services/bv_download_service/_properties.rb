# app/services/bv_download_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BvDownloadService::Properties
#
module BvDownloadService::Properties

  include ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values from config/locales/service.en.yml
  #
  # @type [Hash]
  #
  CONFIGURATION = config_section(:service, :bv_download).deep_freeze

  # Default engine selection.
  #
  # @type [Symbol]
  #
  DEFAULT_ENGINE = production_deployment? ? :production : :staging

  # S3 options are kept in encrypted credentials but can be overridden by
  # environment variables.
  #
  # @type [Hash{Symbol=>String}]
  #
  #--
  # noinspection RubyResolve
  #++
  S3_OPTIONS = {
    region:            BV_REGION,
    access_key_id:     BV_ACCESS_KEY_ID,
    secret_access_key: BV_SECRET_KEY,
  }.compact
   .reverse_merge(Rails.application.credentials.bibliovault || {})
   .except(:bucket)
   .deep_freeze

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

  # The default BiblioVault collections engine API key.
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
