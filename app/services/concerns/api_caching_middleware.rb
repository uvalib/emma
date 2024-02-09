# app/services/concerns/api_caching_middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'caching_middleware'

# Caching for items from an external API.
#
class ApiCachingMiddleware < Faraday::Middleware

  include CachingMiddleware::Concern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default options.
  #
  # @type [Hash{Symbol=>any}]
  #
  DEFAULT_OPTIONS =
    CachingMiddleware::Defaults::DEFAULT_OPTIONS.merge(
      namespace:  'api',
      expires_in: DEFAULT_EXPIRATION,
    ).freeze

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
  def initialize(app, opt = nil)
    opt = DEFAULT_OPTIONS.deep_merge(opt || {})
    @store_options = opt[:store_options] || {}
    @expires_in    = opt[:expires_in] || @store_options[:expires_in]
    @store_options[:expires_in] = @expires_in
    super
  end

  # ===========================================================================
  # :section: CachingMiddleware::Concern overrides
  # ===========================================================================

  public

  # Generate cache key.
  #
  # @param [Faraday::Env] env
  #
  # @return [String]
  # @return [nil]                     If there is no request active.
  #
  def key(env)
    super.sub(/([?&])api=[^&]+/, '\1') # TODO: include user ID
  end

end

__loading_end(__FILE__)
