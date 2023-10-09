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

      def handle_request(client, requests)
        __ext_log
        super
      end

=begin
      def default_server_port(env)
        super
          .tap { |result| __ext_log(result) }
      end
=end

=begin
      def fast_write_str(socket, str)
        start = timestamp
        super
          .tap { __ext_log(start) }
      end
=end

=begin
      def fetch_status_code(status)
        super
          .tap { |result| __ext_log(result) }
      end
=end

=begin
      def normalize_env(env, client)
        __ext_log
        super
      end
=end

=begin
      def req_env_post_parse(env)
        __ext_log
        super
      end
=end

      def str_headers(env, status, headers, res_body, io_buffer, force_keep_alive)
        super
          .tap { __ext_log { { status: status } } }
      end

    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Puma::Request => Puma::RequestDebug if DEBUG_PUMA

__loading_end(__FILE__)
