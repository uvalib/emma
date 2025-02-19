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

  # Cookies to be sent to the IA server.
  #
  # === Implementation Notes
  # These values were obtained from a desktop development VM after installing
  # the "ia" Python script and running "ia configure" with the Email address
  # "emmadso@bookshare.org".  This generates a configuration file ~/.ia which
  # contains an "[s3]" section with the S3 access key and secret, and a
  # "[cookies]" section which contains these values.
  #
  # @see https://archive.org/services/docs/api/internetarchive/quickstart.html#configuring
  #
  IA_COOKIES = {
    'logged-in-user': IA_USER_COOKIE,
    'logged-in-sig':  IA_SIG_COOKIE
  }.map { |name, parts|
    parts = parts.join('; ') if parts.is_a?(Array)
    "#{name}=#{parts}"
  }.join('; ').freeze

  # Headers needed to authenticate with the IA server.
  #
  # @type [Hash{String=>String}]
  #
  IA_HEADERS = {
    Authorization: IA_AUTH,
    Cookie:        IA_COOKIES,
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
