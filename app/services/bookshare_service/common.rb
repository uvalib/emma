# app/services/bookshare_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Common
#
module BookshareService::Common

  include ApiService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, BookshareService::Definition)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Maximum accepted value for a :limit parameter.
  #
  # @type [Integer]
  #
  # == Implementation Notes
  # Determined experimentally.
  #
  MAX_LIMIT = 100

  # For use in example.
  #
  # @type [String]
  #
  DEFAULT_USER = 'anonymous'

  # The identifier (:userAccountId) for the test member "Placeholder Member".
  # (Only usable by "emmadso@bookshare.org".)
  #
  # @type [String, nil]
  #
  #--
  # noinspection SpellCheckingInspection, LongLine
  #++
  BOOKSHARE_TEST_MEMBER = 'AP5xvS_OBOox69jMyt_sdVqCgX-OhnuC8oAFynfN3lJIyM56O86KRMdaYcP5MvZD1DmTtFOSGOj7'
  # Rails.root.join('test/fixtures/members.yml').yield_self { |path|
  #   YAML.load_file(path)&.deep_symbolize_keys! || {}
  # }.dig(:Placeholder_Member, :user_id)

  # ===========================================================================
  # :section:
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

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  public

  # Extract the user name to be used for API parameters.
  #
  # @param [User, String, nil] user
  #
  # @return [String]
  #
  def name_of(user)
    name = user.is_a?(Hash) ? user['uid'] : user
    name.to_s.presence || DEFAULT_USER
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Add service-specific API options.
  #
  # @param [Hash, nil] params         Default: @params.
  #
  # @return [Hash]                    New API parameters.
  #
  def api_options(params = nil)
    super.tap do |result|
      result[:limit] = MAX_LIMIT if result[:limit].to_s == 'max'
    end
  end

end

__loading_end(__FILE__)
