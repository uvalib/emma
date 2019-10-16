# app/helpers/debug_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# DebugHelper
#
module DebugHelper

  def self.included(base)
    __included(base, '[DebugHelper]')
  end

  include GenericHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # OmniAuth endpoint console debugging output.
  #
  # If args[0] is a Symbol it is treated as the calling method; otherwise the
  # calling method is derived from `#caller`.
  #
  # @yield Supplies additional value(s) to output.
  # @yieldreturn [String, Array<String>]
  #
  # @param [Array] args               Value(s) to output.
  #
  # @return [nil]
  #
  def __debug_auth(*args)
    method = args.first.is_a?(Symbol) ? args.shift : calling_method
    part = []
    part << "OMNIAUTH #{method}"
    part << request&.method   if respond_to?(:request)
    part << params.inspect    if respond_to?(:params)
    part += args              if args.present?
    part += Array.wrap(yield) if block_given?
    __debug(part.compact.join(' | '))
  end

  # Exception console debugging output.
  #
  # @param [String]    label
  # @param [Exception] exception
  #
  # @return [nil]
  #
  def __debug_exception(label, exception, **opt)
    opt = opt.reverse_merge(
      api_error_message:   api_error_message,
      'flash.now[:alert]': flash.now[:alert]
    )
    part = []
    part << "!!! #{label} #{exception.class}"
    part << "ERROR: #{exception.message}"
    part << opt.map { |k, v| "#{k} = #{v.inspect}" }
    __debug(part.compact.join(' | '))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  # Neutralize debugging methods when not debugging.
  unless CONSOLE_DEBUGGING
    instance_methods(false).each do |m|
      module_eval "def #{m}(*); end"
    end
  end

end

__loading_end(__FILE__)
