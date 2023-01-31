# app/services/bookshare_service/_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Properties
#
module BookshareService::Properties

  include ApiService::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values from config/locales/service.en.yml.
  #
  # @type [Hash{Symbol=>Any}]
  #
  CONFIGURATION = i18n_erb('emma.service.bookshare').deep_freeze

  # Maximum accepted value for a :limit parameter.
  #
  # @type [Integer]
  #
  # == Implementation Notes
  # Determined experimentally.
  #
  MAX_LIMIT = CONFIGURATION[:max_limit]

  # For use in example.
  #
  # @type [String]
  #
  DEFAULT_USER = CONFIGURATION[:default_user]

  # The primary Bookshare account used for testing.
  #
  # @type [String]
  #
  TEST_ACCOUNT = CONFIGURATION[:test_account]

  # The identifier (:userAccountId) for the test member "Placeholder Member".
  # (Only usable by #TEST_ACCOUNT)
  #
  # @type [String]
  #
  TEST_MEMBER = CONFIGURATION[:test_member]

  # Bookshare accounts used for testing.
  #
  # @type [Array<String>]
  #
  TEST_USERS = Array.wrap(CONFIGURATION[:test_users]).freeze

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

  # The URL for the API connection.
  #
  # @return [String]
  #
  # @see #BOOKSHARE_BASE_URL
  #
  def base_url
    @base_url ||= BOOKSHARE_BASE_URL || super
  end

  # Bookshare API key.
  #
  # @return [String, nil]
  #
  # @see #BOOKSHARE_API_KEY
  #
  def api_key
    BOOKSHARE_API_KEY || super
  end

  # API version is not a part of request URLs.
  #
  # @return [String, nil]
  #
  # @see #BOOKSHARE_API_VERSION
  #
  def api_version
    BOOKSHARE_API_VERSION || super
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
