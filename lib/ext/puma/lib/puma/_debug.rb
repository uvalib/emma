# lib/ext/puma/lib/puma/_debug.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for Puma gem extensions.

__loading_begin(__FILE__)

require 'puma'

module Puma

  module ExtensionDebugging

    if DEBUG_PUMA
      include Emma::Extension::Debugging
    else
      include Emma::Extension::NoDebugging
    end

    # =========================================================================
    # :section: Emma::Extension::Debugging overrides
    # =========================================================================

    public

    def __ext_log_leader
      super('PUMA')
    end

    def __ext_log_tag
      case self
        when Puma::Client  then 'CLI  '
        when Puma::Server  then 'SRV >'
        when Puma::Reactor then 'React'
        else                    '     '
      end
    end

  end

end

__loading_end(__FILE__)
