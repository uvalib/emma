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
# == Authentication and authorization
# Bookshare uses OAuth2, which is handled in this application by Devise and
# OmniAuth.
#
# @see config/initializers/devise.rb
#
class ApiService

  include Api
  include Api::Common
  include Api::Schema

  API_VERSION      = 'v2'
  DEFAULT_BASE_URL = 'https://api.bookshare.org'
  DEFAULT_AUTH_URL = 'https://auth.bookshare.org'
  DEFAULT_API_KEY  = nil # NOTE: Must be supplied at run time.
  DEFAULT_USERNAME = 'rwl@virginia.edu' # For examples # TODO: ???

  BASE_URL =
    (ENV['BOOKSHARE_BASE_URL'] || DEFAULT_BASE_URL)
      .sub(%r{^(https?://)?}) { $1 || 'https://' }
      .sub(%r{(/v\d+/?)?$})   {$1 || "/#{API_VERSION}" }
      .freeze
  AUTH_URL = ENV['BOOKSHARE_AUTH_URL'] || DEFAULT_AUTH_URL
  API_KEY  = ENV['BOOKSHARE_API_KEY']  || DEFAULT_API_KEY

  if running_rails_application?
    Log.error('Missing BOOKSHARE_BASE_URL') unless BASE_URL
    Log.error('Missing BOOKSHARE_AUTH_URL') unless AUTH_URL
    Log.error('Missing BOOKSHARE_API_KEY')  unless API_KEY
  end

  BASE_HOST = URI(BASE_URL).host.freeze
  AUTH_HOST = URI(AUTH_URL).host.freeze

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
  # @option opt [User]   :user          User instance which includes a
  #                                       Bookshare user identity and a token.
  #
  # @option opt [String] :base_url      Base URL to the external service
  #                                       (default: #BASE_URL).
  #
  def initialize(**opt)
    @options  = opt.dup
    @base_url = @options.delete(:base_url) || BASE_URL
    set_user(@options.delete(:user))
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

  # GET # TODO: experimental
  #
  # @param [String]    path
  # @param [Hash, nil] opt
  #
  # @return [String, nil]
  #
  def api_get(path, **opt)
    api(:get, path, opt)&.body&.presence
  end

  # PUT # TODO: experimental
  #
  # @param [String]    path
  # @param [Hash, nil] opt
  #
  # @return [String, nil]
  #
  def api_put(path, **opt)
    api(:put, path, opt)&.body&.presence
  end

  # POST # TODO: experimental
  #
  # @param [String]    path
  # @param [Hash, nil] opt
  #
  # @return [String, nil]
  #
  def api_post(path, **opt)
    api(:post, path, opt)&.body&.presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The single instance of this class.
  #
  # @param [Hash, nil] opt            @see #initialize
  #
  # @return [ApiService]
  #
  # == Implementation Notes
  # The Singleton pattern is avoided so that the instance is unique
  # per-request and not per-thread (potentially spanning multiple requests by
  # different users).
  #
  def self.instance(**opt)
    @@service_instance ||= new(opt)
  end

  # Update the service instance with new information.
  #
  # @param [Hash, nil] opt            @see #initialize
  #
  # @return [ApiService]
  #
  def self.update(**opt)
    @@service_instance ||= nil
    current_user = @service_instance&.user&.uid
    if opt[:user] && opt.except(:user).blank? && (opt[:user] == current_user)
      @@service_instance
    else
      @@service_instance = new(opt)
    end
  end

  # Remove the single instance of the class so that a fresh instance will be
  # generated when #instance is accessed.
  #
  # @return [nil]
  #
  def self.clear
    @@service_instance = nil
  end

end

__loading_end(__FILE__)
