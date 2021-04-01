# app/services/bookshare_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Properties
#
module BookshareService::Properties

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
  BOOKSHARE_CONFIG = i18n_erb('emma.service.bookshare').deep_freeze

  # Maximum accepted value for a :limit parameter.
  #
  # @type [Integer]
  #
  # == Implementation Notes
  # Determined experimentally.
  #
  MAX_LIMIT = BOOKSHARE_CONFIG[:max_limit]

  # For use in example.
  #
  # @type [String]
  #
  DEFAULT_USER = BOOKSHARE_CONFIG[:default_user]

  # The account used for testing.
  #
  # @type [String]
  #
  BOOKSHARE_TEST_ACCOUNT = BOOKSHARE_CONFIG[:test_account]

  # The identifier (:userAccountId) for the test member "Placeholder Member".
  # (Only usable by #BOOKSHARE_TEST_ACCOUNT)
  #
  # @type [String]
  #
  BOOKSHARE_TEST_MEMBER = BOOKSHARE_CONFIG[:test_member]

  # ===========================================================================
  # :section: ApiService::Properties overrides
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  # @see #BOOKSHARE_BASE_URL
  #
  def base_url
    @base_url ||= BOOKSHARE_BASE_URL
  end

  # Bookshare API key.
  #
  # @return [String]
  #
  # @see #BOOKSHARE_API_KEY
  #
  def api_key
    BOOKSHARE_API_KEY
  end

  # API version is not a part of request URLs.
  #
  # @return [nil]
  #
  # @see #BOOKSHARE_API_VERSION
  #
  def api_version
    BOOKSHARE_API_VERSION
  end

end

__loading_end(__FILE__)
