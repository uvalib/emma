# app/services/concerns/middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This stub exists to satisfy the Zeitwerk loader.
module Middleware; end

require 'api_caching_middleware'

Faraday::Middleware.register_middleware(
  instrumentation:        Faraday::Request::Instrumentation,
  api_caching_middleware: ApiCachingMiddleware
)

__loading_end(__FILE__)
