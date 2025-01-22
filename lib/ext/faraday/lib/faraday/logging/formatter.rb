# lib/ext/faraday/lib/faraday/logging/formatter.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Adjust Faraday log formatting.

__loading_begin(__FILE__)

require 'faraday/logging/formatter'

module Faraday

  # Override definitions to be prepended to Faraday::Logging::Formatter.
  #
  # By default, headers are dumped but bodies are not.
  #
  # @example Log request and response message bodies:
  # Faraday.new(...) do |bld|
  #   bld.response :logger, Log.logger, bodies: true
  # end
  #
  # @example Log only request message bodies:
  # Faraday.new(...) do |bld|
  #   bld.response :logger, Log.logger, bodies: { request: true }
  # end
  #
  # @example Log only response message bodies:
  # Faraday.new(...) do |bld|
  #   bld.response :logger, Log.logger, bodies: { response: true }
  # end
  #
  module Logging::FormatterExt

    # Override request log entry to prefix with `@logger.progname`.
    #
    # @param [Faraday::Env] env
    #
    def request(env)
      type = 'request'
      type = "#{@logger.progname}: #{type}" if @logger.progname
      public_send(log_level) do
        # noinspection RubyArgCount
        "#{type}: #{env.method.upcase} #{apply_filters(env.url.to_s)}"
      end
      log_headers(type, env.request_headers) if log_headers?(:request)
      log_body(type, env[:body]) if env[:body] && log_body?(:request)
    end

    # Override response log entry to prefix with `@logger.progname`.
    #
    # @param [Faraday::Env] env
    #
    def response(env)
      type = 'response'
      type = "#{@logger.progname}: #{type}" if @logger.progname
      public_send(log_level) { "#{type}: Status #{env.status}" }
      log_headers(type, env.response_headers) if log_headers?(:response)
      log_body(type, env[:body]) if env[:body] && log_body?(:response)
    end

    # Override exception log entry to prefix with `@logger.progname`.
    #
    # @param [Faraday::Error] exc
    #
    def exception(exc)
      return unless log_errors?
      type = 'error'
      type = "#{@logger.progname}: #{type}" if @logger.progname

      public_send(log_level) { "#{type}: #{exc.full_message}" }

      if exc.respond_to?(:response_headers) && log_headers?(:error)
        log_headers(type, exc.response_headers)
      end
      if exc.respond_to?(:response_body) && log_body?(:error)
        log_body(type, exc.response_body) if exc.response_body
      end
    end

    # Render request headers.
    #
    # @param [Hash] headers
    #
    # @return [String]
    #
    # @see Faraday::Logging::Formatter#dump_headers
    #
    def dump_headers(headers)
      "HEADERS:\n#{super}"
    end

    # Render request dump_body.
    #
    # @param [Hash] body
    #
    # @return [String]
    #
    # @see Faraday::Logging::Formatter#dump_body
    #
    def dump_body(body)
      "BODY:\n#{super.truncate(4096)}"
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Faraday::Logging::Formatter => Faraday::Logging::FormatterExt

__loading_end(__FILE__)
