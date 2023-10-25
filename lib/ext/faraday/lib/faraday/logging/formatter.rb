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

    # Faraday disregards Logger#progname by replacing with an explicit
    # 'request' or 'response' tag.  This corrects that by appending the tag to
    # the progname if it is present.
    #
    # @param [Symbol] log_method    :debug, :info, :warn, etc
    # @param [String] type          'request' or 'response'
    #
    def public_send(log_method, type, &blk)
      progname = [@logger&.progname, type].compact.join(': ')
      super(log_method, progname, &blk) # Object#public_send
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Faraday::Logging::Formatter => Faraday::Logging::FormatterExt

__loading_end(__FILE__)
