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

  API_KEY      = BOOKSHARE_API_KEY
  BASE_URL     = BOOKSHARE_BASE_URL
  API_VERSION  = BOOKSHARE_API_VERSION
  AUTH_URL     = BOOKSHARE_AUTH_URL
  DEFAULT_USER = 'anonymous' # For examples # TODO: ???

  # Validate the presence of these values required for the full interactive
  # instance of the application.
  if rails_application?
    Log.error('Missing BOOKSHARE_API_KEY')  unless API_KEY
    Log.error('Missing BOOKSHARE_BASE_URL') unless BASE_URL
    Log.error('Missing BOOKSHARE_AUTH_URL') unless AUTH_URL
  end

  # Maximum accepted value for a :limit parameter.
  #
  # @type [Integer]
  #
  # == Implementation Notes
  # Determined experimentally.
  #
  MAX_LIMIT = 100

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
  # :section: Authentication
  # ===========================================================================

  public

  # Extract the user name to be used for API parameters.
  #
  # @param [User, String, nil] user
  #
  # @return [String]
  #
  # This method overrides:
  # @see ApiService::Common#name_of
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
  # This method overrides:
  # @see ApiService::Common#api_options
  #
  def api_options(params = nil)
    super.tap do |result|
      result[:limit] = MAX_LIMIT if result[:limit].to_s == 'max'
    end
  end

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  protected

  # Wrap an exception or response in a service error.
  #
  # @param [Exception, Faraday::Response] obj
  #
  # @return [BookshareService::Error]
  #
  # This method overrides:
  # @see ApiService::Common#response_error
  #
  def response_error(obj)
    BookshareService::Error.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [BookshareService::EmptyResultError]
  #
  # This method overrides:
  # @see ApiService::Common#empty_response_error
  #
  def empty_response_error(obj)
    BookshareService::EmptyResultError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [BookshareService::HtmlResultError]
  #
  # This method overrides:
  # @see ApiService::Common#html_response_error
  #
  def html_response_error(obj)
    BookshareService::HtmlResultError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [BookshareService::RedirectionError]
  #
  # This method overrides:
  # @see ApiService::Common#redirect_response_error
  #
  def redirect_response_error(obj)
    BookshareService::RedirectionError.new(obj)
  end

end

__loading_end(__FILE__)
