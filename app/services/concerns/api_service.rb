# app/services/concerns/api_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Send/receive messages to/from a remote service.
#
# @see file:lib/emma/config.rb
# @see file:config/initializers/devise.rb
#
class ApiService

  include Emma::Common
  include Serializable

  include Api

  include ApiService::Properties
  include ApiService::Common
  include ApiService::Definition
  include ApiService::Exceptions
  include ApiService::Identity
  include ApiService::Status

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Internal service options along with connection options.
  #
  # @return [Hash]
  #
  # @see ApiService::Common#SERVICE_OPT
  # @see ApiService::Common#make_connection
  #
  attr_reader :options

  # Initialize a new instance
  #
  # @param [User, nil]   user
  # @param [String, nil] base_url     Base URL to the external service (instead
  #                                     of #BASE_URL defined by the subclass).
  # @param [Hash]        opt          Stored in @options
  #
  def initialize(user: nil, base_url: nil, **opt)
    @options  = opt.compact_blank
    @base_url = base_url
    set_user(user)
  end

  # ===========================================================================
  # :section: ApiService::PerUser
  # ===========================================================================

  public

  module PerUser

    # All services for the given user (or the default services).
    #
    # @param [User, String, nil] user
    #
    # @return [Hash{Class=>ApiService}]
    #
    def self.table(user)
      user = user.account if user.is_a?(User)
      user = user.to_s
      @table ||= {}
      @table[user] ||= {}
    end

    # Remove all services for user
    #
    # @param [User, String] user
    #
    # @return [void]
    #
    def self.clear(user)
      user = user.account if user.is_a?(User)
      if (user = user.to_s).blank?
        Log.debug { "#{self}: cannot clear default services" }
      else
        table(user).clear
      end
    end

  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # A table of all service instances.
  #
  # @param [User, String, nil] user
  #
  # @return [Hash{Class=>ApiService,nil}]
  #
  def self.table(user:, **)
    PerUser.table(user)
  end

  # Remove all service instances.
  #
  # @param [User, String] user
  #
  # @return [void]
  #
  def self.clear(user:, **)
    PerUser.clear(user)
  end

  # The logger for API transmissions.
  #
  # @return [Logger]
  #
  def self.api_logger
    @api_logger ||=
      Log.new(progname: 'API', level: (DEBUG_TRANSMISSION ? :debug : :info))
  end

  # Generate a list of service classes.
  #
  # @param [Class] root               A subclass of ApiService.
  #
  # @param [Array<Class>]
  #
  def self.services(root = ApiService)
    return []     unless root.is_a?(Class) && (root <= ApiService)
    return [root] unless root.subclasses.present?
    root.subclasses.flat_map { services(_1) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Represent the instance as a Hash.
  #
  # @return [Hash{Symbol=>any}]       (no *nil* values)
  #
  def to_h
    { user: user, base_url: @base_url, options: options }.compact
  end

  # ===========================================================================
  # :section: Per-service class methods
  # ===========================================================================

  public

  # Each subclass gets its own distinct set of service state variables.
  #
  # @param [ApiService] subclass
  #
  def self.inherited(subclass)
    subclass.class_exec do

      # =======================================================================
      # Maintain a distinct instance of each service in ApiService#table
      # =======================================================================

      # The single instance of this class.
      #
      # @param [Hash] opt             Passed to ApiService#initialize.
      #
      # @return [ApiService]
      #
      # === Usage Notes
      # For special purposes (like overriding :fatal for all API requests
      # within a single method), use `ApiService.new` rather than
      # `ApiService.instance`.  Providing modified options to this method
      # creates a new single instance; if the options are the same as the
      # current options then the existing instance is returned.
      #
      # === Implementation Notes
      # The Singleton pattern is avoided so that the instance is unique
      # per-request and not per-thread (potentially spanning multiple requests
      # by different users).
      #
      def self.instance(**opt)
        opt = reject_blanks(opt)
        tbl = ApiService.table(user: opt[:user])
        tbl[self] = nil unless opt.except(:user) == tbl[self]&.options
        tbl[self] ||= new(**opt)
      end

      # Remove the single instance of the class so that a fresh instance will
      # be generated the next time #instance is accessed.
      #
      # @return [void]
      #
      def self.clear(**opt)
        ApiService.table(**opt).delete(self)
      end

      # =======================================================================
      # Each service maintains a tables its request methods
      # =======================================================================

      # Add a method name and its properties to #api_methods.
      #
      # @param [Hash{Symbol=>Hash{Symbol=>any}}] prop
      # @param [String, nil]                     topic
      #
      # @return [void]
      #
      # === Usage Notes
      # The definition of each API request method is followed by a block which
      # invokes this method in order to register the properties of the method
      # and its associated API endpoint.  The *prop* argument is expected to be
      # a hash with a single entry whose key is the symbol for the method and
      # whose value is a Hash containing the properties.
      #
      # All keys in the property hash are optional, however :synthetic must
      # be included for methods that do not map on to documented API requests.
      #
      # * :alias        One or more identifiers which associate a method named
      #                 argument with the name of the API parameter it
      #                 represents. (This is not needed for arguments with
      #                 names that are the same as the documented API
      #                 parameter.)
      #
      # * :required     One or more API parameters which are mandatory, which
      #                 may include either Path or Query parameters.
      #
      # * :optional     One or more API optional Query parameters.
      #                 (Path parameters are never optional.)
      #
      # * :multi        An array of one or more parameters that can be passed
      #                 in as a single value or as an array.
      #
      # * :role         If given as :anonymous this is a hint that the request
      #                 should succeed even if the current user is not logged
      #                 in.
      #
      # * :synthetic    If *true*, then the method is not treated as a true API
      #                 method (i.e., it is defined locally but does not map
      #                 directly on to an endpoint defined by the API).
      #
      # * :topic        The base of the module in which the method was defined
      #                 added by this method as a hint for the API Explorer.
      #
      def self.add_api(prop, topic = nil)
        prop = prop.transform_values { _1.merge(topic: topic) } if topic
        (@all_methods  ||= {}).merge!(prop)
        (@true_methods ||= {}).merge!(prop.reject { |_, v| v[:synthetic] })
      end

      # Properties for each method which implements an API request.
      #
      # @param [Hash, Symbol, String, nil] arg
      #
      # @return [Hash, nil]
      #
      #--
      # === Variations
      #++
      #
      # @overload api_methods(arg)
      #   @param [Hash, nil] arg
      #   @option arg [Boolean] :synthetic  Default: false.
      #   @return [Hash{Symbol=>Hash}]      Properties of all methods.
      #
      # @overload api_methods(arg)
      #   @param [Symbol, String] arg       Method name.
      #   @return [Hash, nil]               Properties of the named method.
      #
      # === Usage Notes
      # By default only true (documented) API methods are returned, unless:
      # - If :synthetic is *true* then "fake" methods (which implement
      #     functionality not directly supported by the API) are also included.
      # - If :synthetic is :only then only the "fake" methods are returned.
      #
      def self.api_methods(arg = nil)
        @all_methods  ||= {}
        @true_methods ||= {}
        if arg.is_a?(String) || arg.is_a?(Symbol)
          @all_methods[arg.to_sym]
        elsif (synthetic = (arg.is_a?(Hash) && arg[:synthetic])) == :only
          @all_methods.except(*@true_methods.keys)
        else
          synthetic ? @all_methods : @true_methods
        end
      end

      # =======================================================================
      # Serializers
      # =======================================================================

      protected

      # Create a serializer for this class and any subclasses derived from it.
      #
      # @param [Class] this_class
      #
      # @see Serializer::Base#serialize?
      #
      def self.make_serializers(this_class)
        this_class.class_exec do

          serializer :serialize do |instance|
            instance.to_h
          end

          serializer :deserialize do |hash|
            new(**re_symbolize_keys(hash))
          end

          def self.inherited(subclass)
            make_serializers(subclass)
          end

        end
      end

      make_serializers(self)

    end
  end

end

__loading_end(__FILE__)
