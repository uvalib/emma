# lib/ext/omniauth/lib/omniauth/_debug.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for OmniAuth gem extensions.

__loading_begin(__FILE__)

require 'omniauth'

module OmniAuth

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
      super('OMNIAUTH')
    end

    def __ext_log_tag
      is_a?(OmniAuth::Strategy) ? __ext_class.demodulize.upcase : super
    end

  end

end

__loading_end(__FILE__)
