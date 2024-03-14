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
    #--
    # noinspection SpellCheckingInspection
    #++
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

=begin # NOTE: Puma debugging
      def io_ok?
        super
          .tap { |result| __ext_log(result) }
      end
=end

=begin # NOTE: Puma debugging
      def call
        __ext_log
        super
      end
=end

=begin # NOTE: Puma debugging
      def in_data_phase
        super
          .tap { |result| __ext_log(result) }
      end
=end

      def set_timeout(val)
        super
          .tap { __ext_log { { val: val, '@timeout_at': @timeout_at } } }
      end

=begin # NOTE: Puma debugging
      def timeout
        super
          .tap { |res| __ext_log { { '@timeout_at': @timeout_at, res: res } } }
      end
=end

      def reset(fast_check = true)
        __ext_log { { fast_check: fast_check, '@buffer': @buffer&.size } }
        super
      end

      def close
        __ext_log { {
          timeout_in:      timeout,
          '@buffer':       @buffer&.size,
          '@body_remain':  @body_remain,
          '@parsed_bytes': @parsed_bytes
        } }
        super
      end

=begin # NOTE: Puma debugging
      def try_to_finish
        __ext_log
        super
      end
=end

      def eagerly_finish
        __ext_log { { '@ready': @ready } }
        super
      end

      def finish(timeout)
        __ext_log { { timeout: timeout, '@ready': @ready } }
        super
      end

      def timeout!
        __ext_log { { in_data_phase: in_data_phase } }
        super
      end

      def write_error(status_code)
        __ext_log { { status_code: status_code } }
        super
      end

=begin # NOTE: Puma debugging
      def peerip
        super
          .tap { |result| __ext_log(result) }
      end
=end

=begin # NOTE: Puma debugging
      def can_close?
        super
          .tap { |result| __ext_log(result) }
      end
=end

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
            __ext_log(@partial_part_left) { {
              request_body_wait: @env['puma.request_body_wait']
            } }
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
