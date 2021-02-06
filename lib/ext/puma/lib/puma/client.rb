# lib/ext/puma/lib/puma/client.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Puma gem.

__loading_begin(__FILE__)

require 'puma/client'

module Puma

  if DEBUG_PUMA

    # Overrides adding extra debugging around method calls.
    #
    module ClientDebug

      include Puma::ExtensionDebugging

      # =======================================================================
      # :section: Puma::Client overrides
      # =======================================================================

      public

      def initialize(io, env = nil)
        __ext_log { { io: io, env: env } }
        super
      end

      def set_timeout(val)
        super
          .tap { __ext_log { { '@timeout_at': @timeout_at } } }
      end

=begin
      def timeout
        super
          .tap { __ext_log { { '@timeout_at': @timeout_at } } }
      end
=end

      def reset(fast_check = true)
        __ext_log { { fast_check: fast_check } }
        super
      end

      def close
        __ext_log
        super
      end

=begin
      def try_to_finish
        __ext_log
        super
      end
=end

      def finish(timeout)
        __ext_log { { timeout: timeout } }
        super
      end

      def timeout!
        __ext_log { { in_data_phase: in_data_phase } }
        super
      end

      # =======================================================================
      # :section: Puma::Client overrides
      # =======================================================================

      protected

      def setup_body
        __ext_log
        super
      end

      def read_body
        start = timestamp
        super
          .tap { __ext_log("#{@body_remain} bytes left", start) }
      end

      def read_chunked_body
        __ext_log
        super
      end

      def setup_chunked_body(body)
        __ext_log
        super
      end

      def write_chunk(str)
        start = timestamp
        super
          .tap { __ext_log(start) { @chunked_content_length } }
      end

      def decode_chunk(chunk)
        __ext_log
        start = timestamp
        super
          .tap { __ext_log(start) { @partial_part_left } }
      end

      def set_ready
        super
          .tap do
            __ext_log(@partial_part_left) do
              { request_body_wait: @env['puma.request_body_wait'] }
            end
          end
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Puma::Client => Puma::ClientDebug if DEBUG_PUMA

__loading_end(__FILE__)
