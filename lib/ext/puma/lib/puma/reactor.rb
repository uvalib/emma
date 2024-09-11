# lib/ext/puma/lib/puma/reactor.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Puma gem.

__loading_begin(__FILE__)

require 'puma/reactor'

module Puma

  if DEBUG_PUMA

    # Overrides adding extra debugging around method calls.
    #
    module ReactorDebug

      include Puma::ExtensionDebugging

      # =======================================================================
      # :section: Puma::Reactor overrides
      # =======================================================================

      public

      def run(background = true)
        __ext_log { { background: background } }
        super
      end

      def add(client)
        super
          .tap { __ext_log(_1) }
      end

      def shutdown
        __ext_log
        super
      end

      # =======================================================================
      # :section: Puma::Reactor overrides
      # =======================================================================

      protected

=begin # NOTE: Puma debugging
      def select_loop
        __ext_log
        super
      end
=end

      def register(client)
        __ext_log
        super
      end

=begin # NOTE: Puma debugging
      def wakeup!(client)
        __ext_log
        super
      end
=end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Puma::Reactor => Puma::ReactorDebug if DEBUG_PUMA

__loading_end(__FILE__)
