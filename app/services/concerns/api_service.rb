# app/services/concerns/api_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'middleware'

# Send/receive messages to/from a remote service.
#
# @see file:lib/emma/config.rb
# @see file:config/initializers/devise.rb
#
class ApiService

  include Emma::Common

  include Api

  include_submodules(self)

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
  # @param [User, nil]   user         User instance which includes a
  #                                     Bookshare user identity and token.
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
  # :section: Class methods
  # ===========================================================================

  public

  # A table of all service instances.
  #
  # @return [Hash{Class=>ApiService}]
  #
  def self.table
    @table ||= {}
  end

  # Remove all service instances.
  #
  # @return [void]
  #
  def self.clear
    table.clear
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

    # == Maintain a distinct instance of each service in ApiService#table

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
      def self.instance(**opt)
        opt = reject_blanks(opt)
        srv = ApiService.table[self]
        use_existing   = srv.present?
        use_existing &&= User.match?(opt[:user], srv.user)
        use_existing &&= (opt.except(:user) == srv.options)
        use_existing ? srv : (ApiService.table[self] = new(**opt))
      end

      # Update the service instance with new information.
      #
      # @param [Hash] opt             Passed to #instance.
      #
      # @return [ApiService]
      #
      def self.update(**opt)
        instance(**opt)
      end

      # Remove the single instance of the class so that a fresh instance will
      # be generated the next time #instance is accessed.
      #
      # @return [void]
      #
      def self.clear
        ApiService.table.delete(self)
      end

    end

    # == Each service maintains a tables its request methods

    subclass.class_exec do

      # Add a method name and its properties to #api_methods.
      #
      # @param [Hash{Symbol=>Hash{Symbol=>Any}}] prop
      # @param [String, nil]                     topic
      #
      # @return [void]
      #
      # == Usage Notes
      # The definition of each API request method is followed by a block which
      # invokes this method in order to register the properties of the method
      # and its associated API endpoint.  The *prop* argument is expected to be
      # a hash with a single entry whose key is the symbol for the method and
      # whose value is a Hash containing the properties.
      #
      # All keys in the property hash are optional, however :reference_id must
      # be included for methods that map on to documented API requests.
      #
      # :alias          One or more identifiers which associate a method named
      #                 argument with the name of the API parameter it
      #                 represents. (This is not needed for arguments with
      #                 names that are the same as the documented API
      #                 parameter.)
      #
      # :required       One or more API parameters which are mandatory, which
      #                 may include either Path or Query parameters.
      #
      # :optional       One or more API optional Query parameters.
      #                 (Path parameters are never optional.)
      #
      # :multi          An array of one or more parameters that can be passed
      #                 in as a single value or as an array.
      #
      # :role           If given as :anonymous this is a hint that the request
      #                 should succeed even if the current user is not logged
      #                 in.
      #
      # :reference_id   This is the HTML element ID of the request on the
      #                 Bookshare API documentation page.  If this is not
      #                 provided then the method is not treated as a true API
      #                 method.
      #
      # :topic          The base of the module in which the method was defined
      #                 added by this method as a hint for the API Explorer.
      #
      def self.add_api(prop, topic = nil)
        prop = prop.transform_values { |v| v.merge(topic: topic) } if topic
        (@all_methods  ||= {}).merge!(prop)
        (@true_methods ||= {}).merge!(prop.select { |_, v| v[:reference_id] })
      end

      # Properties for each method which implements an API request.
      #
      # @param [Hash, Symbol, String, nil] arg
      #
      # @return [Hash, nil]
      #
      #--
      # == Variations
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
      # == Usage Notes
      # By default only true (documented) API methods are returned, unless:
      # - If :synthetic is *true* then "fake" methods (which implement
      #     functionality not directly supported by the API) are also included.
      # - If :synthetic is :only then only the "fake" methods are returned.
      #
      def self.api_methods(arg = nil)
        @all_methods  ||= {}
        @true_methods ||= {}
        # noinspection RubyNilAnalysis
        if arg.is_a?(String) || arg.is_a?(Symbol)
          @all_methods[arg.to_sym]
        elsif (synthetic = (arg.is_a?(Hash) && arg[:synthetic])) == :only
          @all_methods.except(*@true_methods.keys)
        else
          synthetic ? @all_methods : @true_methods
        end
      end

    end

  end

end

__loading_end(__FILE__)
