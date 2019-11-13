# app/services/api_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'concerns/middleware'

# Send/receive messages through the Bookshare API.
#
# == Authentication and authorization
# Bookshare uses OAuth2, which is handled in this application by Devise and
# OmniAuth.
#
# @see lib/emma/config.rb
# @see config/initializers/devise.rb
#
class ApiService

  include Api
  include Api::Common
  include Api::Schema

  include GenericHelper

  # Include send and receive modules from "app/services/api_service/*.rb".
  #
  # noinspection RubyYardParamTypeMatch
  if in_debugger?
    include_submodules(self, __FILE__)
  else
    include_submodules(self)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL for the API connection (default: ApiService::Common#BASE_URL).
  #
  # @return [String]
  #
  attr_reader :base_url

  # Internal service options along with connection options.
  #
  # @return [Hash]
  #
  # @see ApiService::Common#SERVICE_OPTIONS
  # @see ApiService::Common#make_connection
  #
  attr_reader :options

  # Initialize a new instance
  #
  # @param [Hash] opt                 Stored in @options except for:
  #
  # @option opt [User]   :user        User instance which includes a
  #                                     Bookshare user identity and a token.
  #
  # @option opt [String] :base_url    Base URL to the external service
  #                                     (default: #BASE_URL).
  #
  def initialize(**opt)
    opt, @options = partition_options(opt, :base_url, :user)
    @options.reject! { |_, v| v.blank? }
    @base_url = opt[:base_url] || BASE_URL
    set_user(opt[:user])
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The single instance of this class.
  #
  # @param [Hash] opt                 Passed to ApiService#initialize.
  #
  # @return [ApiService]
  #
  # == Usage Notes
  # For special purposes (like overriding :no_raise for all API requests within
  # a single method), use `ApiService.new` rather than `ApiService.instance`.
  # Providing modified options to this method creates a new single instance; if
  # the options are the same as the current options then the existing instance
  # is returned.
  #
  # == Implementation Notes
  # The Singleton pattern is avoided so that the instance is unique
  # per-request and not per-thread (potentially spanning multiple requests by
  # different users).
  #
  # noinspection RubyClassVariableUsageInspection, RubyNilAnalysis
  def self.instance(**opt)
    opt = opt.reject { |_, v| v.blank? }
    use_existing   = (@@service_instance ||= nil).present?
    use_existing &&= User.match?(opt[:user], @@service_instance.user)
    use_existing &&= (opt.except(:user) == @@service_instance.options)
    use_existing ? @@service_instance : (@@service_instance = new(opt))
  end

  # Update the service instance with new information.
  #
  # @param [Hash] opt                 Passed to ApiService#initialize.
  #
  # @return [ApiService]
  #
  def self.update(**opt)
    instance(**opt)
  end

  # Remove the single instance of the class so that a fresh instance will be
  # generated the next time #instance is accessed.
  #
  # @return [nil]
  #
  # noinspection RubyClassVariableUsageInspection
  def self.clear
    @@service_instance = nil
  end

end

__loading_end(__FILE__)
