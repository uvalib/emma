# app/services/concerns/middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'api_caching_middleware'

Faraday::Middleware.register_middleware(
  api_caching_middleware: Faraday::ApiCachingMiddleware
)

__loading_end(__FILE__)
