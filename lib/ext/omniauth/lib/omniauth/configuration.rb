# lib/ext/omniauth/lib/omniauth/configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the OmniAuth gem.

__loading_begin(__FILE__)

require 'omniauth'

module OmniAuth

  module ConfigurationExt

    # Indicate whether the request method is configured as allowed.
    #
    # @param [Symbol, String, Rack::Request] method
    #
    def allowed_method?(method)
      method = method.request_method if method.is_a?(Rack::Request)
      allowed_request_methods.include?(method.to_s.downcase.to_sym)
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OmniAuth::Configuration => OmniAuth::ConfigurationExt

__loading_end(__FILE__)
