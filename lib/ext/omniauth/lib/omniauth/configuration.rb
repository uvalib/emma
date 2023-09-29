# lib/ext/omniauth/lib/omniauth/configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the OmniAuth gem.

=begin
__loading_begin(__FILE__)

require 'omniauth'

module OmniAuth

  module ConfigurationExt

    # Indicate whether the request method is configured as allowed.
    #
    # @param [Symbol, String, Rack::Request] meth
    #
    def allowed_method?(meth)
      meth = meth.request_method if meth.is_a?(Rack::Request)
      allowed_request_methods.include?(meth.to_s.downcase.to_sym)
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OmniAuth::Configuration => OmniAuth::ConfigurationExt

__loading_end(__FILE__)
=end
