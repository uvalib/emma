# lib/ext/faraday/lib/faraday/response/logger.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the OAuth2 gem.

__loading_begin(__FILE__)

require 'faraday/response/logger'

module Faraday

  # Override definitions to be prepended to Faraday::Response::Logger.
  #
  module Response::LoggerExt

=begin
    def call(env)
      info('request')    { log_out(env, env.url.to_s) }
      if log_headers?(:request)
        debug('request') { log_out(env, dump_headers(env.request_headers)) }
      end
      if env[:body] && log_body?(:request)
        debug('request') { log_out(env, dump_body(env[:body])) }
      end
      @app.call(env).on_complete do |environment|
        on_complete(environment)
      end
    end

    def dump_headers(headers)
      "HEADERS:\n#{super}"
    end

    def log_out(env, output)
      env.method.to_s.upcase << ' ' << apply_filters(output)
    end
=end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Faraday::Response::Logger => Faraday::Response::LoggerExt

__loading_end(__FILE__)
