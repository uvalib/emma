# lib/ext/puma/lib/puma/request.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Puma gem.

__loading_begin(__FILE__)

require 'puma/request'

module Puma

  if DEBUG_PUMA

    # Overrides adding extra debugging around method calls.
    #
    module RequestDebug

      include Puma::ExtensionDebugging

      # =======================================================================
      # :section: Puma::Request overrides
      # =======================================================================

      public

      def handle_request(client, lines)
        start = timestamp
        super
          .tap { __ext_log(start) }
      end

=begin
      def fast_write(io, str)
        start = timestamp
        super
          .tap { __ext_log(start) }
      end
=end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Puma::Request => Puma::RequestDebug if DEBUG_PUMA

__loading_end(__FILE__)
