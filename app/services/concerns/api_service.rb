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
        @service_instance ||= nil
        $stderr.puts "$$$$$$$$$$$$$$$$$ instance | #{self} | @service_instance = #{@service_instance} | @service_instance.options = #{@service_instance&.options.inspect} | @service_instance.user = #{@service_instance&.user.inspect} | opt = #{opt.inspect}"
        opt = reject_blanks(opt)
        use_existing   = (@service_instance ||= nil).present?
        use_existing &&= User.match?(opt[:user], @service_instance.user)
        use_existing &&= (opt.except(:user) == @service_instance.options)
        use_existing ? @service_instance : (@service_instance = new(**opt))
      end

      # Update the service instance with new information.
      #
      # @param [Hash] opt                 Passed to ApiService#initialize.
      #
      # @return [ApiService]
      #
      def self.update(opt = nil)
        instance(opt)
          .tap do |res|
            $stderr.puts "$$$$$$$$$$$$$$$$$ update   | #{self} | @service_instance = #{@service_instance} | @service_instance.options = #{@service_instance&.options.inspect} | @service_instance.user = #{@service_instance&.user.inspect} | opt = #{opt.inspect}"
          end
      end

      # Remove the single instance of the class so that a fresh instance will
      # be generated the next time #instance is accessed.
      #
      # @return [nil]
      #
      # noinspection RubyClassVariableUsageInspection
      def self.clear
        @service_instance = nil
      end

=begin
      extend ClassMethodDefinitions
=end

      ##include MethodDefinition
      #extend  MethodDefinition

      # Add a method name and its properties to #api_methods.
      #
      # @param [Hash{Symbol=>Hash{Symbol=>*}}] prop
      #
      # @return [void]
      #
      # == Usage Notes
      # The definition of each API request method is followed by a block which
      # invokes this method in order to register the properties of the method and
      # its associated API endpoint.  The *prop* argument is expected to be a hash
      # with a single entry whose key is the symbol for the method and whose value
      # is a Hash containing the properties.
      #
      # All keys in the property hash are optional, however :reference_id must be
      # included for methods that map on to documented API requests.
      #
      # :alias          One or more identifiers which associate a method named
      #                 argument with the name of the API parameter it represents.
      #                 (This is not needed for arguments with names that are the
      #                 same as the documented API parameter.)
      #
      # :required       One or more API parameters which are mandatory, which may
      #                 include either Path or Query parameters.
      #
      # :optional       One or more API optional Query parameters.
      #                 (Path parameters are never optional.)
      #
      # :multi          An array of one or more parameters that can be passed in as
      #                 a single value or as an array.
      #
      # :role           If given as :anonymous this is a hint that the request
      #                 should succeed even if the current user is not logged in.
      #
      # :reference_id   This is the HTML element ID of the request on the Bookshare
      #                 API documentation page.  If this is not provided then the
      #                 method is not treated as a true API method.
      #
      # :topic          The base of the module in which the method was defined
      #                 added by this method as a hint for the API Explorer.
      #
      def self.add_api(prop)
        @all_methods  ||= {}
        $stderr.puts "$$$-----------$$$ add_api | #{self} | #{@all_methods.object_id} | prop = #{prop.inspect}"
        # __output { ". API Request method #{prop.keys.join(', ')}" }
        topic = self.to_s.demodulize
        prop = prop.transform_values { |v| v.merge(topic: topic) }
        (@all_methods  ||= {}).merge!(prop)
        (@true_methods ||= {}).merge!(prop.select { |_, v| v[:reference_id] })
      end

      # Properties for each method which implements an API request.
      #
      # @overload api_methods(arg)
      #   @param [Hash] arg
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
        $stderr.puts "$$$-----------$$$ api_methods | #{self} | #{@all_methods.object_id} | arg = #{arg.inspect}"
        @true_methods ||= {}
        if arg.is_a?(String) || arg.is_a?(Symbol)
          @all_methods[arg.to_sym]
        elsif (synthetic = (arg.is_a?(Hash) && arg[:synthetic])) == :only
          # noinspection RubyYardReturnMatch
          @all_methods.except(*@true_methods.keys)
        else
          synthetic ? @all_methods : @true_methods
        end
      end

    end
  end

=begin
  module MemberMethodDefinitions

    extend ClassMethodDefinitions

    def api_methods(arg = nil)
      self.api_methods(arg)
    end

    # The optional API query parameters for the given method.
    #
    # @param [Symbol, String] method
    #
    # @return [Array<Symbol>]
    #
    def optional_parameters(method)
      api_methods(method)&.dig(:optional)&.keys || []
    end

    # The required API query parameters for the given method.
    #
    # @param [Symbol, String] method
    # @param [Boolean]        all
    #
    # @return [Array<Symbol>]
    #
    # == Usage Notes
    # By default, these are only the Query or FormData parameters that would be
    # the required parameters that are to be passed through the method's "**opt"
    # options hash.  If :all is *true*, the result will also include the method's
    # named parameters (translated to the name used in the documentation [e.g.,
    # "userIdentifier" instead of "user"]).
    #
    def required_parameters(method, all: false)
      result = api_methods(method)&.dig(:required)&.keys || []
      result -= named_parameters(method) unless all
      result
    end

    # The subset of required API request parameters which are passed to the
    # implementation method via named parameters.
    #
    # @param [Symbol, String] method
    # @param [Boolean]        no_alias
    #
    # @return [Array<Symbol>]
    #
    # == Usage Notes
    # By default, the names are translated to the documented parameter names.
    # If :no_alias is *true* then the actual parameter names are returned.
    #
    def named_parameters(method, no_alias: false)
      alias_keys = !no_alias && api_methods(method)&.dig(:alias) || {}
      method(method).parameters.map { |type, name|
        alias_keys[name] || name if %i[key keyreq].include?(type)
      }.compact
    end

  end
=end

  # Add a method name and its properties to #api_methods.
  #
  # @param [Hash{Symbol=>Hash{Symbol=>*}}] prop
  #
  # @return [void]
  #
  # == Usage Notes
  # The definition of each API request method is followed by a block which
  # invokes this method in order to register the properties of the method and
  # its associated API endpoint.  The *prop* argument is expected to be a hash
  # with a single entry whose key is the symbol for the method and whose value
  # is a Hash containing the properties.
  #
  # All keys in the property hash are optional, however :reference_id must be
  # included for methods that map on to documented API requests.
  #
  # :alias          One or more identifiers which associate a method named
  #                 argument with the name of the API parameter it represents.
  #                 (This is not needed for arguments with names that are the
  #                 same as the documented API parameter.)
  #
  # :required       One or more API parameters which are mandatory, which may
  #                 include either Path or Query parameters.
  #
  # :optional       One or more API optional Query parameters.
  #                 (Path parameters are never optional.)
  #
  # :multi          An array of one or more parameters that can be passed in as
  #                 a single value or as an array.
  #
  # :role           If given as :anonymous this is a hint that the request
  #                 should succeed even if the current user is not logged in.
  #
  # :reference_id   This is the HTML element ID of the request on the Bookshare
  #                 API documentation page.  If this is not provided then the
  #                 method is not treated as a true API method.
  #
  # :topic          The base of the module in which the method was defined
  #                 added by this method as a hint for the API Explorer.
  #
  def add_api(prop)
    $stderr.puts "................................ BASE #{__method__} @ #{self}"
    self.class.add_api(prop)
    raise 'This is not working'
  end

  # Properties for each method which implements an API request.
  #
  # @overload api_methods(arg)
  #   @param [Hash] arg
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
  def api_methods(arg = nil)
    $stderr.puts "................................ BASE #{__method__} @ #{self}"
    self.class.api_methods(arg)
    raise 'This is not working'
  end

end

__loading_end(__FILE__)
