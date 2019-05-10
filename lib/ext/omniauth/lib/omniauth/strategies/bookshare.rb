# lib/ext/omniauth/lib/omniauth/strategies/bookshare.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# A extension/customization of OmniAuth::Strategies::OAuth2

__loading_begin(__FILE__)

=begin
require "oauth2"
require "omniauth"
require "securerandom"
require "socket"       # for SocketError
require "timeout"      # for Timeout::Error
=end
require 'ext/oauth2/ext'
require 'omniauth/strategies/oauth2'

module OmniAuth

  module Strategies

    # An extension/customization of OmniAuth::Strategies::OAuth2 which sets up
    # some defaults that would otherwise have to be specified in
    # config/initializers/devise.rb
    #
    class Bookshare < OmniAuth::Strategies::OAuth2

=begin
      include OmniAuth::Strategy

      def self.inherited(subclass)
        OmniAuth::Strategy.included(subclass)
      end
=end

=begin
      args %i[client_id client_secret]
=end

=begin
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

      option :client_id,     ApiService::API_KEY
      option :client_secret, ''
      option :client_options, {
        site:            ApiService::AUTH_URL,
        auth_scheme:     :basic_auth,
        authorize_method: :post, # TODO: ???
        #max_redirects:   0,
        #connection_opts: { headers: { Host: ApiService::AUTH_HOST } }
      }

      option :authorize_options, %i[scope]
      option :authorize_params, {
        scope: 'basic'
      }

      option :token_options, []
      option :token_params, {}

      credentials do
        {
          token:         access_token.token,
          expires:       (expires = access_token.expires?),
          expires_at:    (access_token.expires_at    if expires),
          refresh_token: (access_token.refresh_token if expires)
        }.reject { |_, v| v.nil? }.stringify_keys
      end

      # =======================================================================
      # :section: OmniAuth::Strategy overrides
      # =======================================================================

      public

=begin
      attr_reader :app, :env, :options, :response
=end

=begin
      # Initializes the strategy by passing in the Rack endpoint,
      # the unique URL segment name for this strategy, and any
      # additional arguments. An `options` hash is automatically
      # created from the last argument if it is a hash.
      #
      # @param app [Rack application] The application on which this middleware is applied.
      #
      # @overload new(app, options = {})
      #   If nothing but a hash is supplied, initialized with the supplied options
      #   overriding the strategy's default options via a deep merge.
      # @overload new(app, *args, options = {})
      #   If the strategy has supplied custom arguments that it accepts, they may
      #   will be passed through and set to the appropriate values.
      #
      # @yield [Options] Yields options to block for further configuration.
      def initialize(app, *args, &block) # rubocop:disable UnusedMethodArgument
        @app = app
        @env = nil
        @options = self.class.default_options.dup

        options.deep_merge!(args.pop) if args.last.is_a?(Hash)
        options[:name] ||= self.class.to_s.split('::').last.downcase

        self.class.args.each do |arg|
          break if args.empty?

          options[arg] = args.shift
        end

        # Make sure that all of the args have been dealt with, otherwise error out.
        raise(ArgumentError.new("Received wrong number of arguments. #{args.inspect}")) unless args.empty?

        yield options if block_given?
      end
=end

=begin
      def inspect
        "#<#{self.class}>"
      end
=end

=begin
      # Direct access to the OmniAuth logger, automatically prefixed
      # with this strategy's name.
      #
      # @example
      #   log :warn, "This is a warning."
      def log(level, message)
        OmniAuth.logger.send(level, "(#{name}) #{message}")
      end
=end

=begin
      # Duplicates this instance and runs #call! on it.
      # @param [Hash] The Rack environment.
      def call(env)
        dup.call!(env)
      end
=end

=begin
      # The logic for dispatching any additional actions that need
      # to be taken. For instance, calling the request phase if
      # the request path is recognized.
      #
      # @param env [Hash] The Rack environment.
      def call!(env) # rubocop:disable CyclomaticComplexity, PerceivedComplexity
        unless env['rack.session']
          error = OmniAuth::NoSessionError.new('You must provide a session to use OmniAuth.')
          raise(error)
        end

        @env = env
        @env['omniauth.strategy'] = self if on_auth_path?

        return mock_call!(env) if OmniAuth.config.test_mode
        return options_call if on_auth_path? && options_request?
        return request_call if on_request_path? && OmniAuth.config.allowed_request_methods.include?(request.request_method.downcase.to_sym)
        return callback_call if on_callback_path?
        return other_phase if respond_to?(:other_phase)

        @app.call(env)
      end
=end

=begin
    # Responds to an OPTIONS request.
    def options_call
      OmniAuth.config.before_options_phase.call(env) if OmniAuth.config.before_options_phase
      verbs = OmniAuth.config.allowed_request_methods.collect(&:to_s).collect(&:upcase).join(', ')
      [200, {'Allow' => verbs}, []]
    end
=end

      # Performs the steps necessary to run the request phase of a strategy.
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # This method overrides:
      # @see OmniAuth::Strategy#request_call
      #
      def request_call
        setup_phase
        log :info, 'Request phase initiated.'

        # store query params from the request url, extracted in the callback_phase
        session['omniauth.params'] = request.get? ? request.GET : request.POST
        $stderr.puts "OMNIAUTH #{__method__} | method  = #{request.request_method}"
        $stderr.puts "OMNIAUTH #{__method__} | options = #{options.inspect}"
        $stderr.puts "OMNIAUTH #{__method__} | omniauth.params = #{session['omniauth.params'].inspect}"
        $stderr.puts "OMNIAUTH #{__method__} | session = #{session.to_hash.inspect}"
        OmniAuth.config.before_request_phase&.call(env)

        if !options.form
          if (op = options.origin_param) && (org = request.params[op])
            log :info, "OMNIAUTH #{__method__} | origin from request.params"
            env['rack.session']['omniauth.origin'] = org
          elsif (ref = env['HTTP_REFERER']) && !ref.end_with?(request_path)
            log :info, "OMNIAUTH #{__method__} | origin from HTTP_REFERER"
            env['rack.session']['omniauth.origin'] = ref
          end
          $stderr.puts "OMNIAUTH #{__method__} | env['rack.session']['omniauth.origin'] = #{env['rack.session']['omniauth.origin'].inspect}"
          request_phase

        elsif options.form.respond_to?(:call)
          log :info, 'Rendering form from supplied Rack endpoint.'
          options.form.call(env)

        else # if options.form
          log :info, 'Rendering form from underlying application.'
          call_app!

        end
      end

=begin
      # Performs the steps necessary to run the callback phase of a strategy.
      def callback_call
        setup_phase
        log :info, 'Callback phase initiated.'
        @env['omniauth.origin'] = session.delete('omniauth.origin')
        @env['omniauth.origin'] = nil if env['omniauth.origin'] == ''
        @env['omniauth.params'] = session.delete('omniauth.params') || {}
        OmniAuth.config.before_callback_phase.call(@env) if OmniAuth.config.before_callback_phase
        callback_phase
      end
=end

=begin
      # Returns true if the environment recognizes either the
      # request or callback path.
      def on_auth_path?
        on_request_path? || on_callback_path?
      end
=end

=begin
      def on_request_path?
        if options[:request_path].respond_to?(:call)
          options[:request_path].call(env)
        else
          on_path?(request_path)
        end
      end
=end

=begin
      def on_callback_path?
        on_path?(callback_path)
      end
=end

=begin
      def on_path?(path)
        current_path.casecmp(path).zero?
      end
=end

=begin
      def options_request?
        request.request_method == 'OPTIONS'
      end
=end

=begin
    # The setup phase looks for the `:setup` option to exist and,
    # if it is, will call either the Rack endpoint supplied to the
    # `:setup` option or it will call out to the setup path of the
    # underlying application. This will default to `/auth/:provider/setup`.
    def setup_phase
      if options[:setup].respond_to?(:call)
        log :info, 'Setup endpoint detected, running now.'
        options[:setup].call(env)
      elsif options[:setup]
        log :info, 'Calling through to underlying application for setup.'
        setup_env = env.merge('PATH_INFO' => setup_path, 'REQUEST_METHOD' => 'GET')
        call_app!(setup_env)
      end
    end
=end

=begin
    def uid
      self.class.uid_stack(self).last
    end
=end

=begin
    def info
      merge_stack(self.class.info_stack(self))
    end
=end

=begin
    def credentials
      merge_stack(self.class.credentials_stack(self))
    end
=end

=begin
    def extra
      merge_stack(self.class.extra_stack(self))
    end
=end

=begin
    def auth_hash
      hash = AuthHash.new(:provider => name, :uid => uid)
      hash.info = info unless skip_info?
      hash.credentials = credentials if credentials
      hash.extra = extra if extra
      hash
    end
=end

=begin
    # Determines whether or not user info should be retrieved. This
    # allows some strategies to save a call to an external API service
    # for existing users. You can use it either by setting the `:skip_info`
    # to true or by setting `:skip_info` to a Proc that takes a uid and
    # evaluates to true when you would like to skip info.
    #
    # @example
    #
    #   use MyStrategy, :skip_info => lambda{|uid| User.find_by_uid(uid)}
    def skip_info?
      return false unless options.skip_info?
      return true unless options.skip_info.respond_to?(:call)

      options.skip_info.call(uid)
    end
=end

=begin
    def callback_phase
      env['omniauth.auth'] = auth_hash
      call_app!
    end
=end

=begin
    def path_prefix
      options[:path_prefix] || OmniAuth.config.path_prefix
    end
=end

=begin
    def custom_path(kind)
      if options[kind].respond_to?(:call)
        result = options[kind].call(env)
        return nil unless result.is_a?(String)

        result
      else
        options[kind]
      end
    end
=end

=begin
    def request_path
      @request_path ||= options[:request_path].is_a?(String) ? options[:request_path] : "#{path_prefix}/#{name}"
    end
=end

=begin
    def callback_path
      @callback_path ||= begin
        path = options[:callback_path] if options[:callback_path].is_a?(String)
        path ||= current_path if options[:callback_path].respond_to?(:call) && options[:callback_path].call(env)
        path ||= custom_path(:request_path)
        path ||= "#{path_prefix}/#{name}/callback"
        path
      end
    end
=end

=begin
    def setup_path
      options[:setup_path] || "#{path_prefix}/#{name}/setup"
    end
=end

=begin
    CURRENT_PATH_REGEX = %r{/$}.freeze
    EMPTY_STRING       = ''.freeze
    def current_path
      @current_path ||= request.path_info.downcase.sub(CURRENT_PATH_REGEX, EMPTY_STRING)
    end
=end

=begin
    def query_string
      request.query_string.empty? ? '' : "?#{request.query_string}"
    end
=end

=begin
    def call_app!(env = @env)
      @app.call(env)
    end
=end

=begin
    def full_host
      case OmniAuth.config.full_host
      when String
        OmniAuth.config.full_host
      when Proc
        OmniAuth.config.full_host.call(env)
      else
        # in Rack 1.3.x, request.url explodes if scheme is nil
        if request.scheme && request.url.match(URI::ABS_URI)
          uri = URI.parse(request.url.gsub(/\?.*$/, ''))
          uri.path = ''
          # sometimes the url is actually showing http inside rails because the
          # other layers (like nginx) have handled the ssl termination.
          uri.scheme = 'https' if ssl? # rubocop:disable BlockNesting
          uri.to_s
        else ''
        end
      end
    end
=end

=begin
    def callback_url
      full_host + script_name + callback_path + query_string
    end
=end

=begin
    def script_name
      @env['SCRIPT_NAME'] || ''
    end
=end

=begin
    def session
      @env['rack.session']
    end
=end

=begin
    def request
      @request ||= Rack::Request.new(@env)
    end
=end

=begin
    def name
      options[:name]
    end
=end

=begin
    def redirect(uri)
      r = Rack::Response.new

      if options[:iframe]
        r.write("<script type='text/javascript' charset='utf-8'>top.location.href = '#{uri}';</script>")
      else
        r.write("Redirecting to #{uri}...")
        r.redirect(uri)
      end

      r.finish
    end
=end

=begin
    def user_info
      {}
    end
=end

=begin
    def fail!(message_key, exception = nil)
      env['omniauth.error'] = exception
      env['omniauth.error.type'] = message_key.to_sym
      env['omniauth.error.strategy'] = self

      if exception
        log :error, "Authentication failure! #{message_key}: #{exception.class}, #{exception.message}"
      else
        log :error, "Authentication failure! #{message_key} encountered."
      end

      OmniAuth.config.on_failure.call(env)
    end
=end

=begin
    def dup
      super.tap do
        @options = @options.dup
      end
    end
=end

      # =======================================================================
      # :section: OmniAuth::Strategy overrides
      # =======================================================================

      protected

=begin
      def merge_stack(stack)
        stack.inject({}) do |a, e|
          a.merge!(e)
          a
        end
      end
=end

=begin
      def ssl?
        request.env['HTTPS'] == 'on' ||
          request.env['HTTP_X_FORWARDED_SSL'] == 'on' ||
          request.env['HTTP_X_FORWARDED_SCHEME'] == 'https' ||
          (request.env['HTTP_X_FORWARDED_PROTO'] && request.env['HTTP_X_FORWARDED_PROTO'].split(',')[0] == 'https') ||
          request.env['rack.url_scheme'] == 'https'
      end
=end

      # =======================================================================
      # :section: OmniAuth::Strategies::OAuth2 overrides
      # =======================================================================

      public

=begin
      attr_accessor :access_token
=end

=begin
      def client
        ::OAuth2::Client.new(
          options.client_id,
          options.client_secret,
          options.client_options.deep_symbolize_keys
        )
      end
=end

      # request_phase
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#request_phase
      #
      # == Implementation Notes
      # NOTE: There is currently a problem going directly to authorize_url.
      # For some reason (probably related to headers), Location is returned
      # as "https://auth.staging.bookshare.org/user_login", which fails.
      # This extra step is necessary so that the Location can be edited (along
      # with a modification to OAuth2::ClientExt#request to rewrite the
      # Location received from "https://auth.bookshare.org/oauth/authorize").
      #
      # @see OAuth2::ClientExt#request
      #
      def request_phase
        auth_code = client.auth_code
        auth_parm = authorize_params.reverse_merge(redirect_uri: callback_url)
        auth_url  = auth_code.authorize_url(auth_parm)
        $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__} | method        = #{request.request_method.inspect}"
        $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__} | client        = #{client.inspect}"
        $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__} | authorize_url = #{auth_url.inspect}"

        # NOTE: temporarily(?) fixing Bookshare redirect problem...
        auth_url = client.request(:get, auth_url).response.env.url

        redirect(auth_url)

=begin # NOTE: The following does *not* work:
        Rack::Response.new { |r|
          r.write("Redirecting to #{auth_url}...")
          r.set_header('Host', ApiService::AUTH_HOST)
          r.redirect(auth_url)
        }.finish
=end
      end

      # authorize_params
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#authorize_params
      #
      def authorize_params
        $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__}"
        options.authorize_params[:state] = SecureRandom.hex(24)
        options.authorize_params.merge(options_for('authorize')).tap do |params|
          if OmniAuth.config.test_mode
            @env ||= {}
            @env['rack.session'] ||= {}
          end
          session['omniauth.state'] = params[:state]
=begin
          $stderr.puts "OMNIAUTH-OAUTH2 #{__method__} => #{result.inspect}"
=end
        end
      end

      # token_params
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#token_params
      #
      def token_params
        $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__}"
        options.token_params.merge(options_for('token'))
          .tap { |result|
            $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__} => #{result.inspect}"
          }
      end

      # callback_phase
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#callback_phase
      #
      def callback_phase
        $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__}"
        e = result = nil
        p = request.params.reject { |_, v| v.blank? }
        error = p['error_reason'] || p['error']

        if error
          description = p['error_description'] || p['error_reason']
          raise CallbackError.new(error, description, p['error_uri'])
        end

        unless options.provider_ignores_state
          unless p['state'] == session.delete('omniauth.state')
            error = :csrf_detected
            raise CallbackError.new(error, 'CSRF detected')
          end
        end

        self.access_token = build_access_token
        self.access_token = access_token.refresh! if access_token.expired?
        #super
        env['omniauth.auth'] = auth_hash
        result = call_app!

      rescue ::OAuth2::Error, CallbackError => e
        error ||= :invalid_credentials

      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        error = :timeout

      rescue ::SocketError => e
        error = :failed_to_connect

      ensure
        fail!(error, e) if error
        return result
      end

      # =======================================================================
      # :section: OmniAuth::Strategies::OAuth2 overrides
      # =======================================================================

      protected

      # build_access_token
      #
      # @return [OAuth2::AccessToken]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#build_access_token
      #
      def build_access_token
        $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__}"
        code   = request.params['code']
        opts   = options.auth_token_params.deep_symbolize_keys
        params = token_params.to_hash(symbolize_keys: true)
        params[:redirect_uri] ||= callback_url
        client.auth_code.get_token(code, params, opts)
          .tap { |result|
            $stderr.puts "OMNIAUTH-BOOKSHARE #{__method__} => #{result.inspect}"
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

      # options_for
      #
      # @param [String, Symbol] option
      #
      # @return [Hash]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#options_for
      #
      def options_for(option)
        option_keys = options[:"#{option}_options"]
        options.slice(*option_keys).symbolize_keys
      end

    end

  end

end

__loading_end(__FILE__)
