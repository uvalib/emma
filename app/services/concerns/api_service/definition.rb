# app/services/concerns/api_service/definition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Interface to the shared data structure which holds the definition of the API
# requests and parameters.
#
module ApiService::Definition

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Add a method name and its properties to #api_methods.
  #
  # The actual functionality is defined within ApiService#inherited -- this
  # method exposes it to the modules containing the methods which implement
  # individual API endpoints.
  #
  # @param [Hash{Symbol=>Hash{Symbol=>Any}}] prop
  #
  # @return [void]
  #
  # @see ApiService#add_api
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def add_api(prop)
    class_name   = is_a?(Module) ? name : self.class.name
    name_parts   = class_name.split('::')
    topic        = name_parts.pop
    service_name = name_parts[...-1].join('::')
    service_name.constantize.add_api(prop, topic)
  end

  # Properties for each method which implements an API request.
  #
  # The actual functionality is defined within ApiService#inherited -- this
  # method exposes it to the modules containing the methods which implement
  # individual API endpoints.
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
  #   Return properties of all methods.
  #   @param [Hash] arg
  #   @option arg [Boolean] :synthetic  Default: false.
  #
  # @overload api_methods(arg)
  #   Properties of the named method or *nil*.
  #   @param [Symbol, String] arg       Method name.
  #
  # @see ApiService#api_methods
  #
  def api_methods(arg = nil)
    self.class.ancestors.first&.api_methods(arg)
  end

  # The optional API query parameters for the given method.
  #
  # @param [Symbol, String] meth
  #
  # @return [Array<Symbol>]
  #
  def optional_parameters(meth)
    api_methods(meth)&.dig(:optional)&.keys || []
  end

  # The required API query parameters for the given method.
  #
  # @param [Symbol, String] meth
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
  def required_parameters(meth, all: false)
    result = api_methods(meth)&.dig(:required)&.keys || []
    result -= named_parameters(meth) unless all
    result
  end

  # The subset of required API request parameters which are passed to the
  # implementation method via named parameters.
  #
  # @param [Symbol, String] meth
  # @param [Boolean]        no_alias
  #
  # @return [Array<Symbol>]
  #
  # == Usage Notes
  # By default, the names are translated to the documented parameter names.
  # If :no_alias is *true* then the actual parameter names are returned.
  #
  def named_parameters(meth, no_alias: false)
    alias_keys = !no_alias && api_methods(meth)&.dig(:alias) || {}
    method(meth).parameters.map { |type, name|
      alias_keys[name] || name if %i[key keyreq].include?(type)
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
