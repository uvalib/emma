# lib/ext/oauth2/lib/oauth2/_debug.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for OAuth2 gem extensions.

=begin # NOTE: OAuth2 disabled
__loading_begin(__FILE__)

require 'oauth2'

module OAuth2

  module ExtensionDebugging

    if DEBUG_OAUTH
      include Emma::Extension::Debugging
    else
      include Emma::Extension::NoDebugging
    end

    # =========================================================================
    # :section: Emma::Extension::Debugging overrides
    # =========================================================================

    public

    def __ext_log_leader
      super('OAUTH2')
    end

  end

end

__loading_end(__FILE__)
=end
