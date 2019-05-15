# lib/ext/faraday/api_caching_middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'caching_middleware'

module Faraday

  # Default values for Bookshare API middleware.
  #
  module ApiCachingMiddlewareDefaults

    include CachingMiddlewareDefaults

    # Default options.
    #
    DEFAULT_OPTIONS =
      CachingMiddlewareDefaults::DEFAULT_OPTIONS.merge(
        namespace:  'api',
        expires_in: DEFAULT_EXPIRATION,
        ).deep_freeze

  end

  # Caching for items from the Bookshare API.
  #
  class ApiCachingMiddleware < Faraday::Middleware

    include CachingMiddlewareConcern
    include ApiCachingMiddlewareDefaults

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize an instance.
    #
    # @param [Faraday::Middleware] app
    # @param [Hash, nil]           opt
    #
    # @option opt [Logger]                              :logger
    # @option opt [String]                              :cache_dir
    # @option opt [Symbol, ActiveSupport::Cache::Store] :store
    # @option opt [Hash]                                :store_options
    # @option opt [ActiveSupport::Duration, Integer]    :expires_in
    #
    # This method overrides:
    # @see Faraday::CachingMiddlewareConcern#initialize
    #
    def initialize(app, opt = nil)
      opt = DEFAULT_OPTIONS.deep_merge(opt || {})
      @store_options = opt[:store_options] || {}
      @expires_in    = opt[:expires_in] || @store_options[:expires_in]
      @store_options[:expires_in] = @expires_in
      super(app, opt)
    end

    # =========================================================================
    # :section: Faraday::CachingMiddlewareConcern overrides
    # =========================================================================

    public

    # Generate cache key.
    #
    # @param [Faraday::Env] env
    #
    # @return [String, nil]
    #
    # This method overrides:
    # @see Faraday::CachingMiddlewareConcern#key
    #
    def key(env)
      super.sub(/([?&])api=[^&]+/, '\1') # TODO: include user ID
    end

  end

end

__loading_end(__FILE__)
