# app/services/api_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/common'
require 'api/error'
require 'api/schema'

require_subdir(__FILE__)

# Send/receive messages through the Bookshare API.
#
class ApiService

  include Api
  include Api::Common
  include Api::Schema

  API_VERSION = 'v2'

  BASE_URL = ENV['BOOKSHARE_BASE_URL'] || 'https://api.bookshare.org'
  AUTH_URL = ENV['BOOKSHARE_AUTH_URL'] || BASE_URL
  API_KEY  = ENV['BOOKSHARE_API_KEY']
  CB_URL   = ENV['BOOKSHARE_CB_URL']

  # Maximum accepted value for a :limit parameter.
  #
  # @type [Integer]
  #
  # == Implementation Notes
  # Determined experimentally.
  #
  MAX_LIMIT = 100

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [String]
  attr_reader :base_url

  # @return [String]
  attr_reader :auth_url

  # @return [String]
  attr_accessor :callback_url

  # @return [String]
  attr_reader :user

  # @return [Hash]
  attr_reader :options

  # @return [Faraday::Response, nil]
  attr_reader :response

  # @return [Exception, nil]
  attr_reader :exception

  # Initialize a new instance
  #
  # @param [Hash, nil] opt
  #
  # @option opt [String] :base_url      Base URL to the external service
  #                                       (default: #BASE_URL).
  #
  # @option opt [String] :auth_url      Base URL for OAuth requests
  #                                       (default: #AUTH_URL).
  #
  # @option opt [String] :callback_url  Base URL for OAuth callbacks
  #                                       (default: #CB_URL).
  #
  # @option opt [String] :user
  #
  def initialize(**opt)
    opt = opt.dup
    @base_url     = opt.delete(:base_url)     || BASE_URL
    @auth_url     = opt.delete(:auth_url)     || AUTH_URL
    @callback_url = opt.delete(:callback_url) || CB_URL
    @user         = opt.delete(:user)         || API_KEY # TODO: testing
    @options      = opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TMP_INITIAL_INSTANCE_METHODS = instance_methods

  # Include send and receive modules from "app/services/api_service/*/*.rb".
  constants(false).each do |name|
    mod = "#{self}::#{name}".constantize
    include mod if mod.is_a?(Module)
  end

  SERVICE_METHODS =
    (instance_methods - TMP_INITIAL_INSTANCE_METHODS).select { |m|
      m if m =~ /^(get|create|update|remove|download)_/
    }.compact.sort.freeze

  remove_const(:TMP_INITIAL_INSTANCE_METHODS)

  # service_methods
  #
  # @param [Array<Symbol>]
  #
  def service_methods
    SERVICE_METHODS
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The single instance of this class.
  #
  # @param [Hash, String, Boolean, nil] params (Re-)set authorization token.
  #
  # @return [ApiService]
  #
  # == Implementation Notes
  # The Singleton pattern is avoided so that the instance is unique
  # per-request and not per-thread (potentially spanning multiple requests by
  # different users).
  #
  def self.instance(params = nil)
    (@@service_instance ||= new).tap do |service|
      if params.is_a?(FalseClass)
        # Do not request authorization yet.

      elsif params.is_a?(Hash) && params[:code].present?
        # Authorization code grant flow.
        service.set_authorization_code(params)

      elsif params.present?
        # Implicit grant flow.
        service.set_token(params)

      elsif !service.authorized?
        # Request authorization.
        service.generate_token
      end
    end
  end

end

__loading_end(__FILE__)
