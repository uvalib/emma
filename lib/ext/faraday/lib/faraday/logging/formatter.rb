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

    def dump_headers(headers)
      "HEADERS:\n#{super}"
    end

    def dump_body(body)
      "BODY:\n#{super}"
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Faraday::Logging::Formatter => Faraday::Logging::FormatterExt

__loading_end(__FILE__)
