# app/services/concerns/api_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'middleware'

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

  include Emma::Common
  include Api

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # @param [User]   user              User instance which includes a
  #                                     Bookshare user identity and token.
  # @param [String] base_url          Base URL to the external service (instead
  #                                     of #BASE_URL defined by the subclass).
  # @param [Hash]   opt               Stored in @options
  #
  def initialize(user: nil, base_url: nil, **opt)
    @options  = opt.reject { |_, v| v.blank? }
    @base_url = base_url
    set_user(user)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Each subclass gets its own instance variable.
  #
  # @param [ApiService] subclass
  #
  def self.inherited(subclass)
    subclass.class_exec do

      # The single instance of this class.
      #
      # @param [Hash] opt             Passed to ApiService#initialize.
      #
      # @return [ApiService]
      #
      # == Usage Notes
      # For special purposes (like overriding :no_raise for all API requests
      # within a single method), use `ApiService.new` rather than
      # `ApiService.instance`.  Providing modified options to this method
      # creates a new single instance; if the options are the same as the
      # current options then the existing instance is returned.
      #
      # == Implementation Notes
      # The Singleton pattern is avoided so that the instance is unique
      # per-request and not per-thread (potentially spanning multiple requests
      # by different users).
      #
      # noinspection RubyClassVariableUsageInspection, RubyNilAnalysis
      def self.instance(opt = nil)
        opt = reject_blanks(opt)
        use_existing   = (@@service_instance ||= nil).present?
        use_existing &&= User.match?(opt[:user], @@service_instance.user)
        use_existing &&= (opt.except(:user) == @@service_instance.options)
        use_existing ? @@service_instance : (@@service_instance = new(**opt))
      end

      # Update the service instance with new information.
      #
      # @param [Hash] opt                 Passed to ApiService#initialize.
      #
      # @return [ApiService]
      #
      def self.update(opt = nil)
        instance(opt)
      end

      # Remove the single instance of the class so that a fresh instance will
      # be generated the next time #instance is accessed.
      #
      # @return [nil]
      #
      # noinspection RubyClassVariableUsageInspection
      def self.clear
        @@service_instance = nil
      end

    end
  end

end

__loading_end(__FILE__)
