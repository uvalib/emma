# lib/ext/sprockets/lib/sprockets/manifest.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Sprockets gem overrides.

__loading_begin(__FILE__)

require_relative '_debug'
require 'sprockets/manifest'

module Sprockets

  module ManifestExt

    # Redefine @logger to be an Emma::Logger.
    #
    # @return [Emma::Logger]
    #
    def logger
      @logger ||= Sprockets.local_logger(level: Log::INFO)
    end

  end

end

override Sprockets::Manifest => Sprockets::ManifestExt

__loading_end(__FILE__)
