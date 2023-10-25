# lib/ext/active_support/lib/active_support/log_subscriber.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/log_subscriber'

module ActiveSupport

  module LogSubscriberExt

    # Also check whether log output is globally suppressed.
    #
    # @param [*] event
    #
    def silenced?(event)
      super || ::Logger.suppressed?
    end

  end

end

# =============================================================================
# Override class definitions
# =============================================================================

override ActiveSupport::LogSubscriber => ActiveSupport::LogSubscriberExt

__loading_end(__FILE__)
