# app/controllers/concerns/user/debug_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# User::DebugConcern
#
module User::DebugConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'User::DebugConcern')
  end

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
  def auth_debug(*args)
    method = (args.shift if args.first.is_a?(Symbol))
    method ||= caller(1,1).to_s.sub(/^[^`]*`(.*)'[^']*$/, '\1')
    part = []
    part << "OMNIAUTH #{method}"
    part << request&.method   if respond_to?(:request)
    part << params.inspect    if respond_to?(:params)
    part += args              if args.present?
    part += Array.wrap(yield) if block_given?
    __debug(part.join(' | '))
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
