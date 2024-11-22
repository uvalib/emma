# lib/ext/sprockets/lib/sprockets/cache.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Sprockets::Cache and Sprockets::Cache::FileStore overrides.

__loading_begin(__FILE__)

require_relative '_debug'
require 'sprockets/cache'

module Sprockets

  module CacheLoggerExt

    # This is used to redefine the class methods to use Emma::Logger.
    #
    # @return [Emma::Logger]
    #
    def default_logger
      @def_logger ||= Sprockets.local_logger(progname: 'SPROCKETS CACHE')
    end

  end

  class Cache

    extend CacheLoggerExt

    class FileStore
      extend CacheLoggerExt
    end

  end

end

__loading_end(__FILE__)
