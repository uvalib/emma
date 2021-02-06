# lib/ext/shrine/lib/shrine/_debug.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for Shrine gem extensions.

__loading_begin(__FILE__)

require 'shrine'

class Shrine

  module ExtensionDebugging

    if DEBUG_SHRINE
      include Emma::Extension::Debugging
    else
      include Emma::Extension::NoDebugging
    end

    # =========================================================================
    # :section: Emma::Extension::Debugging overrides
    # =========================================================================

    public

    def __ext_log_leader
      super('SHRINE')
    end

  end

end

__loading_end(__FILE__)
