# lib/ext/puma/lib/puma/server.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Puma gem.

__loading_begin(__FILE__)

require 'puma/server'

module Puma

  if DEBUG_PUMA

    # Overrides adding extra debugging around method calls.
    #
    module ServerDebug

      include Puma::ExtensionDebugging

      # =======================================================================
      # :section: Puma::Server overrides
      # =======================================================================

      public

      def initialize(app, events = nil, options = {})
        __ext_log { { options: options } }
        super
      end

=begin
      def inherit_binder(bind)
        __ext_log
        super
      end
=end

=begin
      def run(background = true, thread_name: 'srv')
        __ext_log { { background: background, thread_name: thread_name } }
        super
      end
=end

=begin
      def reactor_wakeup(client)
        __ext_log { stats }
        super
      end
=end

=begin
      def handle_servers
        __ext_log { stats }
        super
      end
=end

      def process_client(client)
        __ext_log { stats }
        super
      end

      def with_force_shutdown(client, &block)
        __ext_log { stats }
        super
      end

      def client_error(e, client, requests = 1)
        __ext_log(e)
        super
      end

      def graceful_shutdown
        __ext_log { stats }
        super
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Puma::Server => Puma::ServerDebug if DEBUG_PUMA

__loading_end(__FILE__)
