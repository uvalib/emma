# lib/ext/omniauth-oauth2/lib/omniauth/strategies/oauth2.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Omniauth-OAuth2 gem.

__loading_begin(__FILE__)

require 'ext/oauth2/ext'
require 'ext/omniauth/ext'
require 'omniauth/strategies/oauth2'

module OmniAuth

  module Strategies

    module OAuth2Ext

      include OmniAuth::StrategyExt

=begin
      def self.inherited(subclass)
        OmniAuth::Strategy.included(subclass)
      end
=end

=begin
      args %i[client_id client_secret]

      option :client_id, nil
      option :client_secret, nil
      option :client_options, {}
      option :authorize_params, {}
      option :authorize_options, [:scope]
      option :token_params, {}
      option :token_options, []
      option :auth_token_params, {}
      option :provider_ignores_state, false
=end

=begin
      attr_accessor :access_token
=end

      def client
        ::OAuth2::Client.new(options.client_id, options.client_secret, deep_symbolize(options.client_options))
      end

=begin
      credentials do
        hash = {"token" => access_token.token}
        hash["refresh_token"] = access_token.refresh_token if access_token.expires? && access_token.refresh_token
        hash["expires_at"] = access_token.expires_at if access_token.expires?
        hash["expires"] = access_token.expires?
        hash
      end
=end

      def request_phase
        _client    = client
        _auth_code = _client.auth_code
        _auth_url  = _auth_code.authorize_url({:redirect_uri => callback_url}.merge(authorize_params))
        $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} | client        = #{_client.inspect}"
        $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} | authorize_url = #{_auth_url.inspect}"
        redirect _auth_url
=begin
        redirect client.auth_code.authorize_url({:redirect_uri => callback_url}.merge(authorize_params))
=end
      end

      def authorize_params
=begin
        options.authorize_params[:state] = SecureRandom.hex(24)
        params = options.authorize_params.merge(options_for("authorize"))
        if OmniAuth.config.test_mode
          @env ||= {}
          @env["rack.session"] ||= {}
        end
        session["omniauth.state"] = params[:state]
        params
=end
=begin
        super.tap { |result|
          $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} => #{result.inspect}"
        }
=end
        super
      end

      def token_params
=begin
        options.token_params.merge(options_for("token"))
=end
        super.tap { |result|
          $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} => #{result.inspect}"
        }
      end

      def callback_phase
        $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} | omniauth.origin = #{@env['omniauth.origin'].inspect}"
        $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} | omniauth.params = #{@env['omniauth.params'].inspect}"
        $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} | omniauth.auth   = #{@env['omniauth.auth'].inspect}"
        super
=begin
        error = request.params["error_reason"] || request.params["error"]
        if error
          fail!(error, CallbackError.new(request.params["error"], request.params["error_description"] || request.params["error_reason"], request.params["error_uri"]))
        elsif !options.provider_ignores_state && (request.params["state"].to_s.empty? || request.params["state"] != session.delete("omniauth.state"))
          fail!(:csrf_detected, CallbackError.new(:csrf_detected, "CSRF detected"))
        else
          self.access_token = build_access_token
          self.access_token = access_token.refresh! if access_token.expired?
          super
        end
      rescue ::OAuth2::Error, CallbackError => e
        fail!(:invalid_credentials, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        fail!(:timeout, e)
      rescue ::SocketError => e
        fail!(:failed_to_connect, e)
=end
      end

    protected

      def build_access_token
=begin
        verifier = request.params["code"]
        client.auth_code.get_token(verifier, {:redirect_uri => callback_url}.merge(token_params.to_hash(:symbolize_keys => true)), deep_symbolize(options.auth_token_params))
=end
        super.tap { |result|
          $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} => #{result.inspect}"
        }
      end

=begin
      def deep_symbolize(options)
        hash = {}
        options.each do |key, value|
          hash[key.to_sym] = value.is_a?(Hash) ? deep_symbolize(value) : value
        end
        hash
      end
=end

=begin
      def options_for(option)
        hash = {}
        options.send(:"#{option}_options").select { |key| options[key] }.each do |key|
          hash[key.to_sym] = options[key]
        end
        hash
      end
=end

=begin
      # An error that is indicated in the OAuth 2.0 callback.
      # This could be a `redirect_uri_mismatch` or other
      class CallbackError < StandardError
        attr_accessor :error, :error_reason, :error_uri

        def initialize(error, error_reason = nil, error_uri = nil)
          self.error = error
          self.error_reason = error_reason
          self.error_uri = error_uri
        end

        def message
          [error, error_reason, error_uri].compact.join(" | ")
        end
      end
=end

    end

  end

end

=begin
OmniAuth.config.add_camelization "oauth2", "OAuth2"
=end

# =============================================================================
# Override gem definitions
# =============================================================================

override OmniAuth::Strategies::OAuth2 => OmniAuth::Strategies::OAuth2Ext

__loading_end(__FILE__)
