# app/services/concerns/caching_middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/concern'
require 'faraday'

module CachingMiddleware

  # Common middleware default values.
  #
  module Defaults

    # Base temporary directory.
    TMP_ROOT_DIR =
      ENV['TMPDIR']&.sub(/^([^\/])/, "#{Rails.root}/\\1")&.freeze || Dir.tmpdir

    # Directory for caching.
    CACHE_ROOT_DIR = File.join(TMP_ROOT_DIR, 'cache').freeze

    # Faraday cache directory for :file_store.
    FARADAY_CACHE_DIR = File.join(CACHE_ROOT_DIR, 'faraday').freeze

=begin # TODO: redis cache?
    # Redis server cache configuration.
    RAILS_CONFIG = Rails.application.config_for(:redis).deep_symbolize_keys
=end

    # Default expiration time.
    DEFAULT_EXPIRATION = 1.hour

    # Default options appropriate for any including class.
    #
    DEFAULT_OPTIONS = {
=begin # TODO: redis cache?
      store:  :redis_cache_store,
=end
      store:  :file_store,
      logger: Log.logger,
    }.freeze

  end unless defined?(CachingMiddleware::Defaults)

  # A common implementation for locally-defined caching middleware.
  #
  module Concern

    extend ActiveSupport::Concern

    include CachingMiddleware::Defaults

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @return [Logger, nil]
    attr_reader :logger

    # @return [String]
    attr_reader :http_header

    # @return [ActiveSupport::Cache::Store]
    attr_reader :store

    # @return [Hash]
    attr_reader :store_options

    # @return [Array<String>]
    attr_reader :cacheable_paths

    # Initialize
    #
    # @param [Faraday::Middleware] app
    # @param [Hash, nil]           opt
    #
    # @option opt [Logger]                              :logger
    # @option opt [String]                              :cache_dir
    # @option opt [Symbol, ActiveSupport::Cache::Store] :store
    # @option opt [Hash]                                :store_options
    # @option opt [String]                              :http_header
    # @option opt [Array<String>]                       :cacheable_paths
    #
    def initialize(app, opt = nil)
      @app = app
      opt  = DEFAULT_OPTIONS.deep_merge(opt || {})
      @namespace = opt[:namespace]
      raise 'including class must define :namespace' if @namespace.blank?
      @logger          = opt[:logger]
      @cache_dir       = opt[:cache_dir]
      @http_header     = opt[:http_header] || "x-faraday-#{@namespace}-cache"
      @store           = opt[:store]
      @store_options   = opt[:store_options]
      @cacheable_paths = Array.wrap(opt[:cacheable_paths]).presence
      initialize_logger
      initialize_store
    end

    # Generate cache key.
    #
    # @param [Faraday::Env] env
    #
    # @return [String]
    # @return [nil]                   If there is no request active.
    #
    def key(env)
      request_url(env)
    end

    # call
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response]
    # @return [nil]
    #
    def call(env)
      dup.call!(env)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Report the expiration based on the requested path.
    #
    # @param [Faraday::Env] _env
    #
    # @return [Numeric]
    #
    def expiration(_env = nil)
      DEFAULT_EXPIRATION
    end

    # request_url
    #
    # @param [Faraday::Env] env
    #
    # @return [String]
    # @return [nil]                   If there is no request active.
    #
    def request_url(env)
      env&.url&.request_uri
    end

    # call!
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response]
    # @return [nil]
    #
    def call!(env)
      cache_key = key(env)
      if !cacheable?(env)
        @app.call(env)
      elsif complete?(env)
        log_status(env, cache_key, 'complete')
        to_response(env)
      elsif (response_env = read_cache(env, cache_key))
        to_response(response_env)
      else
        # noinspection RubyScope
        @app.call(env).on_complete do |response_env|
          if response_env
            response_env.response_headers[http_header] = 'MISS'
            write_cache(response_env, cache_key)
          else
            log("request failed for #{cache_key}")
          end
        end
      end
    end

    # Indicate whether the given request is eligible for caching.
    #
    # @param [Faraday::Env] env
    #
    def cacheable?(env)
      result = false
      if (url = request_url(env)).blank?
        log("NO URI for request #{env.inspect}")
      elsif cacheable_paths&.none? { |path| url.include?(path) }
        log("NON-CACHEABLE URI: #{url}")
      else
        result = true
      end
      result
    end

    # Does the request/response indicate that it holds a completed response.
    #
    # @param [Faraday::Env] env
    #
    def complete?(env)
      hit_status(env).present?
    end

    # Show whether the request/response has been updated with a hit status.
    #
    # @param [Faraday::Env] env
    #
    # @return [String]                Either 'HIT' or 'MISS'.
    # @return [nil]                   No request or response active.
    #
    def hit_status(env)
      env&.response_headers&.dig(http_header) ||
        env&.request_headers&.dig(http_header)
    end

    # read_cache
    #
    # @param [Faraday::Env] env
    # @param [String, nil]  cache_key
    #
    # @return [Faraday::Env]
    # @return [nil]                   Could not determine *cache_key*.
    #
    def read_cache(env, cache_key = nil)
      return unless cache_key ||= key(env)
      @store.fetch(cache_key).tap do |response_env|
        response_env.response_headers[http_header] = 'HIT' if response_env
        log_status(response_env, cache_key)
      end
    end

    # write_cache
    #
    # @param [Faraday::Env] env
    # @param [String, nil]  cache_key
    #
    # @return [TrueClass, FalseClass]
    # @return [nil]                   Could not determine *cache_key*.
    #
    def write_cache(env, cache_key = nil)
      return unless (cache_key ||= key(env))
      @store.write(cache_key, env, cache_opt(env)).tap do |success|
        status = (' FAILED:' unless success)
        log("cache WRITE:#{status} #{cache_key}")
      end
    end

    # Generate options to override the default cache options set in the
    # initializer based on the nature of the request.
    #
    # @param [Faraday::Env] env
    #
    # @return [Hash]
    #
    def cache_opt(env)
      { expires_in: expiration(env) }
    end

    # to_response
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response]
    #
    def to_response(env)
      env = env.dup
      response = Faraday::Response.new
      response.finish(env) unless env.parallel?
      env.response = response
    end

    # log
    #
    # @param [String] message
    #
    # @return [nil]
    #
    def log(message)
      __debug { "Faraday #{message}" }
      logger&.info("Faraday #{message}")
      nil
    end

    # log_status
    #
    # @param [Faraday::Env] env
    # @param [String, nil]  cache_key
    # @param [String, nil]  note
    #
    # @return [nil]
    #
    def log_status(env, cache_key = nil, note = nil)
      status = (hit_status(env) == 'HIT') ? 'HIT: ' : 'MISS:'
      cache_key ||= key(env)
      note &&= " [#{note}]"
      log("cache #{status} #{cache_key}#{note}")
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # Run from #initialize to set up the logger.
    #
    # @return [void]
    #
    def initialize_logger
      return if @logger.blank?
      log = @logger
      log = log.to_s if log.is_a?(Pathname)
      if log.is_a?(String)
        log = File.join(TMP_ROOT_DIR, log) unless log.start_with?('/')
        @logger =
          Logger.new(log).tap { |l| l.level = Logger.const_get(@log_level) }
      end
      unless @logger.is_a?(Logger)
        raise "expected String, got #{log.class} #{log.inspect}"
      end
    end

    # Run from #initialize to set up the cache store.
    #
    # @return [void]
    #
    def initialize_store
      if (type = @store).is_a?(Symbol)
        params  = []
        options = @store_options&.dup || {}
        case type
          when :file_store
            @cache_dir ||= File.join(FARADAY_CACHE_DIR, @namespace)
            @cache_dir ||= FARADAY_CACHE_DIR
            params << @cache_dir
          when :redis_cache_store
=begin # TODO: redis cache?
            options.merge!(RAILS_CONFIG)
=end
            options.merge!(namespace: @namespace)
          else
            abort "unexpected type #{type.inspect}"
        end
        params << options
        @store = ActiveSupport::Cache.lookup_store(type, *params)
      end
      unless @store.is_a?(ActiveSupport::Cache::Store)
        raise "expected Symbol, got #{@store.class} #{@store.inspect}"
      end
    end

  end

end

__loading_end(__FILE__)
