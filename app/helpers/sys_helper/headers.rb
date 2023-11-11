# app/helpers/sys_helper/headers.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Headers

  include SysHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Request header values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def request_headers_section(**opt)
    dt_dd_section(request_headers_names, **opt)
  end

  # Rails header values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def rails_headers_section(**opt)
    dt_dd_section(rails_headers_names, **opt)
  end

  # Rack header values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def rack_headers_section(**opt)
    dt_dd_section(rack_headers_names, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Request header `request.env` names.
  #
  # @return [Array<String>]
  #
  def request_headers_names
    # noinspection SpellCheckingInspection
    @request_headers_names ||=
      header_names { |a|

        # From ActionDispatch::Constants
        a.concat string_constants(ActionDispatch::Constants)

        # From ActionDispatch::Request
        a.concat ActionDispatch::Request::ENV_METHODS
        a << 'HTTPS'
        a << 'HTTP_AUTHORIZATION'
        a << 'HTTP_CONTENT_MD5'
        a << 'HTTP_EXPECT'
        a << 'HTTP_RANGE'
        a << 'HTTP_REFERER'
        a << 'HTTP_X_ACCEL_MAPPING'
        a << 'HTTP_X_REQUESTED_WITH'
        a << 'HTTP_X_SENDFILE_TYPE'
        a << 'ORIGINAL_FULLPATH'
        a << 'RAW_POST_DATA'
        a << 'REDIRECT_X_HTTP_AUTHORIZATION'
        a << 'SERVER_SOFTWARE'
        a << 'X-HTTP_AUTHORIZATION'
        a << 'X_HTTP_AUTHORIZATION'

        # From ActionDispatch::Http::Cache::Request
        a << 'Date'
        a << 'Last-Modified'
        a << 'HTTP_IF_MATCH'
        a << 'HTTP_IF_MODIFIED_SINCE'
        a << 'HTTP_IF_NONE_MATCH'

        # From Rack
        a.concat string_constants(Rack)
        a.concat string_constants(Rack::Cors,    'HTTP_')
        a.concat string_constants(Rack::Request, 'HTTP_')
        a << 'CONTENT_LENGTH'
        a << 'CONTENT_TYPE'
        a << 'HTTP_USER_AGENT'
        a << 'HTTP_X_REAL_IP'

        # From WebSocket
        a << 'HTTP_CONNECTION'
        a << 'HTTP_SEC_WEBSOCKET_KEY'
        a << 'HTTP_SEC_WEBSOCKET_KEY1'
        a << 'HTTP_SEC_WEBSOCKET_KEY2'
        a << 'HTTP_SEC_WEBSOCKET_PROTOCOL'
        a << 'HTTP_SEC_WEBSOCKET_VERSION'
        a << 'HTTP_UPGRADE'
        a << 'REQUEST_URI'

        # From Puma
        a << 'HTTP_TRANSFER_ENCODING'
        a << 'SSL_CIPHER'
        a << 'SSL_CIPHER_ALGKEYSIZE'
        a << 'SSL_CIPHER_USEKEYSIZE'
        a << 'SSL_CLIENT_CERT'
        a << 'SSL_CLIENT_CERT_CHAIN_0'
        a << 'SSL_PROTOCOL'
        a << 'SSL_SERVER_CERT'

        # Apache @see https://httpd.apache.org/docs/2.4/mod/mod_rewrite.html
        a << 'CONN_REMOTE_ADDR'
        a << 'CONTEXT_DOCUMENT_ROOT'
        a << 'CONTEXT_PREFIX'
        a << 'HTTP_FORWARDED'
        a << 'HTTP_PROXY_CONNECTION'
        a << 'REMOTE_PORT'
        a << 'REQUEST_FILENAME'
        a << 'REQUEST_SCHEME'
        a << 'SCRIPT_FILENAME'

        a.remove ActionDispatch::Request::HTTP_METHODS + %w[LINK UNLINK]
        a.delete_if { |v| v.start_with?('rack.') }
      }.partition { |v| v.match?(/[a-z]/) }.flat_map(&:itself).deep_freeze
  end

  # Rails header `request.env` names.
  #
  # @return [Array<String>]
  #
  def rails_headers_names
    # noinspection SpellCheckingInspection
    @rails_headers_names ||=
      header_names { |a|
        a.concat Rails.application.env_config.keys

        # From ActionCable
        a << 'async.callback'
        a << 'stream.send'

        # From ActionController
        a << 'action_controller.csrf_token'
        a << 'action_controller.instance'

        # From ActionDispatch
        a << 'action_dispatch.authorized_host'
        a << 'action_dispatch.blocked_hosts'
        a << 'action_dispatch.exception'
        a << 'action_dispatch.original_path'
        a << 'action_dispatch.original_request_method'
        a << 'action_dispatch.remote_ip'
        a << 'action_dispatch.request.query_parameters'
        a << 'action_dispatch.request.request_parameters'
        a << 'action_dispatch.request_id'
        a << 'action_dispatch.route_uri_pattern'
        a << 'action_dispatch.routes.default_url_options'

        # From ActionDispatch::Flash
        a << 'action_dispatch.request.flash_hash'

        # From ActionDispatch::Http::MimeNegotiation
        a << 'action_dispatch.original_path'
        a << 'action_dispatch.request.accepts'
        a << 'action_dispatch.request.content_type'
        a << 'action_dispatch.request.formats'

        # From ActionDispatch::Http::Parameters
        a << 'action_dispatch.request.parameters'
        a << 'action_dispatch.request.path_parameters'

        # From ActionDispatch::Session::CookieStore
        a << 'action_dispatch.request.unsigned_session_cookie'

        # From Puma
        a << 'puma.config'
        a << 'puma.peercert'
        a << 'puma.request_body_wait'
        a << 'puma.socket'

        # From Warden
        a << 'warden'

      }.deep_freeze
  end

  # Rack header `request.env` names.
  #
  # @return [Array<String>]
  #
  def rack_headers_names
    # noinspection SpellCheckingInspection
    @rack_headers_names ||=
      header_names { |a|
        a.concat string_constants(Rack, 'RACK_')
        a.concat string_constants(Puma::Const, 'RACK_')
        a << 'protection.failed'
        a << 'rack.early_hints'
        a << 'rack.protection.attack'
        a.remove %w[rack.input rack.session rack.session.options]
      }.deep_freeze
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A pattern to filter out #string_constants results which are not actually
  # header names.
  #
  # @type [Regexp]
  #
  HEADER_NAME = /^[a-z_][a-z0-9_.-]*\??$/i

  # Build a sorted list of request header names.
  #
  # @param [Array] array
  #
  # @return [Array<String>]
  #
  def header_names(array = [])
    if block_given?
      array = array.dup
      added = yield(array).presence
      array.concat(Array.wrap(added)) if added && !added.equal?(array)
    end
    array.select { |v| v.is_a?(String) && v.match?(HEADER_NAME) }.sort.uniq
  end

  # Return the values of the constants defined in the class or module which
  # are strings.
  #
  # @param [Module]              mod
  # @param [String, Regexp, nil] matching
  #
  # @return [Array<String>]
  #
  def string_constants(mod, matching = nil)
    mod.constants.map { |constant|
      case matching
        when String then next unless constant.start_with?(matching)
        when Regexp then next unless constant.to_s.match?(matching)
      end
      value = mod.const_get(constant)
      value if value.is_a?(String)
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
