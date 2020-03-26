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
  module Logging::FormatterExt

    # Initialize a Formatter instance, turning on output of the request body.
    #
    # @param [Logger] logger
    # @param [Hash]   options
    #
    # This method overrides:
    # @see Faraday::Logging::Formatter#initialize
    #
    def initialize(logger:, options:)
      super
      @options[:bodies] = true
    end

    # Render request headers.
    #
    # @param [Hash] headers
    #
    # @return [String]
    #
    # This method overrides:
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
    # This method overrides:
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
