# app/services/concerns/api_service/definition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Interface to the shared data structure which holds the definition of the API
# requests and parameters.
#
module ApiService::Definition

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
=begin
    # __output { ". API Request method #{prop.keys.join(', ')}" }
    topic = self.to_s.demodulize
    prop = prop.transform_values { |v| v.merge(topic: topic) }
    (@@all_methods  ||= {}).merge!(prop)
    (@@true_methods ||= {}).merge!(prop.select { |_, v| v[:reference_id] })
=end
    base_class = self.to_s.split('::').first.constantize
    if base_class == self
      $stderr.puts "................................ self == base_class == #{self}"
    else
      $stderr.puts "................................ base_class is #{base_class}"
    end
    base_class = self.class if base_class == self
    base_class.add_api(prop)
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
=begin
    @@all_methods  ||= {}
    @@true_methods ||= {}
    if arg.is_a?(String) || arg.is_a?(Symbol)
      @@all_methods[arg.to_sym]
    elsif (synthetic = (arg.is_a?(Hash) && arg[:synthetic])) == :only
      # noinspection RubyYardReturnMatch
      @@all_methods.except(*@@true_methods.keys)
    else
      synthetic ? @@all_methods : @@true_methods
    end
=end
    $stderr.puts "................................ ancestors == #{self.class.ancestors}"
    $stderr.puts "................................ name == #{self.to_s.split('::')}"
    base_class = self.class.ancestors.first
    if base_class == self
      $stderr.puts "................................ self == base_class == #{self}"
    else
      $stderr.puts "................................ base_class is #{base_class}"
    end
    base_class = self.class if base_class == self
    base_class.api_methods(arg)
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

__loading_end(__FILE__)
