# lib/ext/action_dispatch/lib/action_dispatch/middleware/debug_exceptions.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# ActionDispatch logging overrides.

__loading_begin(__FILE__)

require 'action_dispatch/middleware/debug_exceptions'

module ActionDispatch

  module DebugExceptionsExt

    # This gets rid of the "noise" from `#log_error` which causes extra blank
    # lines to be logged around every error.
    #
    def log_array(logger, lines, request)
      lines.compact_blank!
      super
    end

  end

end

# =============================================================================
# Override definitions
# =============================================================================

override ActionDispatch::DebugExceptions => ActionDispatch::DebugExceptionsExt

__loading_end(__FILE__)
