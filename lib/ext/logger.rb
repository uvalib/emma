# lib/ext/logger.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for ::Logger.

__loading_begin(__FILE__)

require 'logger'

class Logger

  module SuppressionExt

    require 'request_store'

    SUPPRESSION_STORE_KEY = :app_logging_suppressed

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def suppressed?
      suppressed.present?
    end

    def suppressed
      RequestStore.store[SUPPRESSION_STORE_KEY]
    end

    def suppressed=(state)
      # noinspection RubySimplifyBooleanInspection
      RequestStore.store[SUPPRESSION_STORE_KEY] = !!state
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include SuppressionExt

  module Ext

    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include SuppressionExt
      # :nocov:
    end

    # Override to avoid logging if suppressed.
    #
    # @param [Integer]  severity
    # @param [any, nil] message
    # @param [any, nil] progname      Default @progname
    #
    # @return [TrueClass]
    #
    def add(severity, message = nil, progname = nil)
      # noinspection RubyMismatchedReturnType
      suppressed? || super
    end

  end

end

# =============================================================================
# Override class definitions
# =============================================================================

override Logger => Logger::Ext

__loading_end(__FILE__)
