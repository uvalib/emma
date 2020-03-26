# lib/ext/omniauth/lib/omniauth/strategies/bookshare.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# A extension of OmniAuth::Strategies::OAuth2.

__loading_begin(__FILE__)

require 'ext/oauth2/ext'
require 'omniauth/strategies/oauth2'

module OmniAuth

  module Strategies

    # An extension of OmniAuth::Strategies::OAuth2 which sets up some defaults
    # that would otherwise have to be specified in initializers/devise.rb.
    #
    # @see https://github.com/omniauth/omniauth-oauth2
    #
    class Bookshare < OmniAuth::Strategies::OAuth2

      include Emma::Debug

      # Pre-authorized users for development purposes.
      #
      # @type [Hash{String=>Hash}]
      #
      # == Usage Notes
      # These exist because Bookshare has a problem with its authentication
      # flow, so tokens were generated for two EMMA users which could be used
      # directly (avoiding the OAuth2 flow).
      #
      CONFIGURED_AUTH =
        BOOKSHARE_TEST_USERS.transform_values { |token|
          { access_token: token, token_type: 'bearer', scope: 'basic' }
        }.deep_freeze

=begin
      include OmniAuth::Strategy

      def self.inherited(subclass)
        OmniAuth::Strategy.included(subclass)
      end
=end

      args %i[client_id client_secret]

      option :client_id,     BOOKSHARE_API_KEY
      option :client_secret, ''
      option :client_options, {
        site:             BOOKSHARE_AUTH_URL,
        auth_scheme:      :basic_auth,
        authorize_method: :post, # TODO: ???
        # max_redirects:   0,
        # connection_opts: { headers: { Host: URI(BOOKSHARE_AUTH_URL).host } }
      }
      option :authorize_options,      %i[scope]
      option :authorize_params,       { scope: 'basic' }
      option :token_options,          []
      option :token_params,           {}
      option :provider_ignores_state, false

      credentials do
        {
          token:         access_token.token,
          expires:       (expires = access_token.expires?),
          expires_at:    (access_token.expires_at    if expires),
          refresh_token: (access_token.refresh_token if expires)
        }.compact.stringify_keys
      end

      # The following are called only after authentication has succeeded.

      uid do
        raw_info[:username].to_s.downcase
      end

      info do
        {
          first_name: raw_info.dig(:name, :firstName),
          last_name:  raw_info.dig(:name, :lastName),
          email:      raw_info[:username]
        }
      end

=begin
      extra do # TODO: ???
        {
          raw_info: raw_info
        }
      end
=end

      # Information about the user account.
      #
      # @return [Hash{Symbol=>Object}]
      #
      # == Implementation Notes
      # NOTE: Needs to relate to:
      # @see BookshareService::UserAccount#get_user_identity
      #
      # E.g.:
      #
      # {
      #   username: 'john@smith.com',
      #   links: [],
      #   name: {
      #     firstName: 'John',
      #     lastName:  'Smith',
      #     middle:    nil,
      #     prefix:    nil,
      #     suffix:    nil,
      #     links:     []
      #   }
      # }
      #
      def raw_info
        @raw_info ||=
          access_token.get("#{BOOKSHARE_BASE_URL}/me").parsed
            .deep_symbolize_keys
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

      # Direct access to the OmniAuth logger, automatically prefixed with this
      # strategy's name.
      #
      # == Implementation Note
      # Instead of attempting to  override Configuration#default_logger this
      # override simply manages its own logger instance
      #
      def log(level, message)
=begin
        OmniAuth.logger.send(level, "(#{name}) #{message}")
=end
        @log ||= Log.new(STDERR)
        @log.add(Log.log_level(level)) { "omniauth: (#{name}) #{message}" }
      end

=begin
      # Duplicates this instance and runs #call! on it.
      # @param [Hash] The Rack environment.
      def call(env)
        dup.call!(env)
      end
=end

      # The logic for dispatching any additional actions that need
      # to be taken. For instance, calling the request phase if
      # the request path is recognized.
      #
      # @param env [Hash] The Rack environment.
      def call!(env) # rubocop:disable CyclomaticComplexity, PerceivedComplexity
        #__debug_items("OMNIAUTH #{__method__}") { env }
        super
=begin
        unless env['rack.session']
          error = OmniAuth::NoSessionError.new('You must provide a session to use OmniAuth.')
          raise(error)
        end

        @env = env
        @env['omniauth.strategy'] = self if on_auth_path?

        return mock_call!(env) if OmniAuth.config.test_mode
        return options_call if on_auth_path? && options_request?
        return request_call if on_request_path? && OmniAuth.config.allowed_method?(request)
        return callback_call if on_callback_path?
        return other_phase if respond_to?(:other_phase)

        @app.call(env)
=end
      end

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
        __debug((dbg = "OMNIAUTH-BOOKSHARE #{__method__}"))
        setup_phase
        log :info, 'Request phase initiated.'

        # Store query params to be passed back via #callback_call.
        session['omniauth.params'] = request.get? ? request.GET : request.POST
        __debug_line(dbg, "method  = #{request.request_method}")
        __debug_line(dbg, "options = #{options.inspect}")
        __debug_line(dbg, "session = #{session.inspect}")
        OmniAuth.config.before_request_phase&.call(env)

        if current_user
          log :info, 'By-passing request_phase.'
          authorize_params # Generate session['omniauth.state']
          request.params['state'] = session['omniauth.state']
          callback_phase

        elsif !options.form
          org = request.params[options.origin_param]
          ref = env['HTTP_REFERER']
          ref = nil if ref&.end_with?(request_path)
          if org || ref
            log :info, "Origin from #{org ? 'request.params' : 'HTTP_REFERER'}"
            env['rack.session']['omniauth.origin'] = org || ref
          end
          __debug_line(dbg) do
            "env['rack.session']['omniauth.origin'] = #{(org || ref).inspect}"
          end
          request_phase

        elsif options.form.respond_to?(:call)
          log :info, 'Rendering form from supplied Rack endpoint.'
          options.form.call(env)

        else # if options.form
          log :info, 'Rendering form from underlying application.'
          call_app!

        end
      end

      # Performs the steps necessary to run the callback phase of a strategy.
      def callback_call
        __debug("OMNIAUTH #{__method__}")
        super
=begin
        setup_phase
        log :info, 'Callback phase initiated.'
        @env['omniauth.origin'] = session.delete('omniauth.origin')
        @env['omniauth.origin'] = nil if env['omniauth.origin'] == ''
        @env['omniauth.params'] = session.delete('omniauth.params') || {}
        OmniAuth.config.before_callback_phase.call(@env) if OmniAuth.config.before_callback_phase
        callback_phase
=end
      end

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
      # This is called in lieu of the normal request process in the event that
      # OmniAuth has been configured to be in test mode.
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # This method overrides:
      # @see OmniAuth::Strategy#mock_call!
      #
      def mock_call!(*)
        if on_request_path? && OmniAuth.config.allowed_method?(request)
          mock_request_call
        elsif on_callback_path?
          mock_callback_call
        else
          call_app!
        end
      end
=end

=begin
      # mock_request_call
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # This method overrides:
      # @see OmniAuth::Strategy#mock_request_call
      #
      def mock_request_call
        setup_phase
        log :info, 'MOCK - Request phase initiated.'

        # Store query params from the request URL extracted in #callback_phase.
        session['omniauth.params'] = request.get? ? request.GET : request.POST
        $stderr.puts "OMNIAUTH #{__method__} | method  = #{request.request_method}"
        $stderr.puts "OMNIAUTH #{__method__} | options = #{options.inspect}"
        $stderr.puts "OMNIAUTH #{__method__} | omniauth.params = #{session['omniauth.params'].inspect}"
        $stderr.puts "OMNIAUTH #{__method__} | session = #{session.to_hash.inspect}"
        OmniAuth.config.before_request_phase&.call(env)

        if (op = options.origin_param) && (org = request.params[op])
          log :info, "OMNIAUTH #{__method__} | origin from request.params"
          env['rack.session']['omniauth.origin'] = org
        elsif (ref = env['HTTP_REFERER']) && !ref.end_with?(request_path)
          log :info, "OMNIAUTH #{__method__} | origin from HTTP_REFERER"
          env['rack.session']['omniauth.origin'] = ref
        end
        $stderr.puts "OMNIAUTH #{__method__} | env['rack.session']['omniauth.origin'] = #{env['rack.session']['omniauth.origin'].inspect}"
        redirect(callback_url)
      end
=end

=begin
      # mock_callback_call
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # This method overrides:
      # @see OmniAuth::Strategy#mock_callback_call
      #
      def mock_callback_call
        setup_phase
        log :info, 'MOCK - Callback phase initiated.'
        @env['omniauth.origin'] = session.delete('omniauth.origin')
        @env['omniauth.origin'] = nil if env['omniauth.origin'] == ''
        @env['omniauth.params'] = session.delete('omniauth.params') || {}

        mocked_auth = OmniAuth.mock_auth_for(name)
        if mocked_auth.is_a?(Symbol)
          fail!(mocked_auth)
        else
          @env['omniauth.auth'] = mocked_auth
          OmniAuth.config.before_callback_phase&.call(@env)
          call_app!
        end
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

      # call_app!
      #
      # @return [*]
      #
      # This method overrides:
      # @see OmniAuth::Strategy#call_app!
      #
      def call_app!(env = @env)
        __debug_items("OMNIAUTH #{__method__}") { env }
        super
=begin
        @app.call(env)
=end
      end

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

      # The OAuth2 client instance.
      #
      # @return [::OAuth2::Client]
      #
      def client
        @client ||=
          ::OAuth2::Client.new(
            options.client_id,
            options.client_secret,
            deep_symbolize(options.client_options)
          ).tap do |result|
            result.options[:redirect_uri] ||= callback_url
            __debug { "OMNIAUTH-BOOKSHARE #{__method__} => #{result.inspect}" }
          end
      end

      # request_phase
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#request_phase
      #
      # @see OAuth2::ClientExt#request
      #
      def request_phase
        dbg  = "OMNIAUTH-BOOKSHARE #{__method__} | #{request.request_method}"
        __debug(dbg)
        code = client.auth_code
        ##prms = authorize_params.reverse_merge(redirect_uri: callback_url)
        #prms = authorize_params.reverse_merge('redirect_uri' => callback_url)
        prms = authorize_params
        url  = code.authorize_url(prms)
        __debug { "#{dbg} => authorize_url = #{url.inspect}" }
        redirect(url)
      end

      # authorize_params
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#authorize_params
      #
      def authorize_params
        super.tap do |result|
          __debug { "OMNIAUTH-BOOKSHARE #{__method__} => #{result.inspect}" }
        end
=begin
        options.authorize_params[:state] = SecureRandom.hex(24)
        options.authorize_params.merge(options_for('authorize')).tap do |params|
          if OmniAuth.config.test_mode
            @env ||= {}
            @env['rack.session'] ||= {}
          end
          session['omniauth.state'] = params[:state]
        end
=end
      end

      # token_params
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#token_params
      #
      def token_params
        super.tap do |result|
          __debug { "OMNIAUTH-BOOKSHARE #{__method__} => #{result.inspect}" }
        end
=begin
        options.token_params.merge(options_for('token'))
=end
      end

      # callback_phase
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#callback_phase
      #
      # noinspection RubyScope
      def callback_phase
        __debug((dbg = "OMNIAUTH-BOOKSHARE #{__method__}"))
        result = e = nil
        params = request.params.reject { |_, v| v.blank? }
        error  = params['error_reason'] || params['error']

        # Raise an exception if the response indicated an error.
        if error
          description = params['error_description'] || params['error_reason']
          raise CallbackError.new(error, description, params['error_uri'])
        end

        # Raise an exception if the returned state doesn't match.
        unless options.provider_ignores_state
          unless params['state'] == session.delete('omniauth.state')
            error = :csrf_detected
            raise CallbackError.new(error, 'CSRF detected')
          end
        end

        # noinspection RubyStringKeysInHashInspection
        result =
          if (username = current_user&.uid)
            # Special case for a fixed user causes a redirect to the special
            # endpoint for direct sign-in.
            self.access_token        = configured_access_token(username)
            session['omniauth.auth'] = configured_auth_hash(username)
            [302, { 'Location' => "/users/sign_in_as?id=#{username}" }, []]

          else
            # Normal case results in a call to the remote service.
            self.access_token = build_access_token
            self.access_token = access_token.refresh! if access_token.expired?
            env['omniauth.auth'] = auth_hash
            call_app!

          end

      rescue ::OAuth2::Error, CallbackError => e
        __debug_line(dbg, 'INVALID', e.class, e.message)
        error ||= :invalid_credentials

      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        __debug_line(dbg, 'TIMEOUT', e.class, e.message)
        error = :timeout

      rescue ::SocketError => e
        __debug_line(dbg, 'CONNECT', e.class, e.message)
        error = :failed_to_connect

      rescue => e
        __debug_line(dbg, 'EXCEPTION', e.class, e.message)

      ensure
        fail!(error, e) if error
        return result
      end

      # =======================================================================
      # :section: OmniAuth::Strategies::OAuth2 overrides
      # =======================================================================

      protected

      # Acquire the OAuth token from the remote service.
      #
      # @return [OAuth2::AccessToken]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#build_access_token
      #
      def build_access_token
        __debug((dbg = "OMNIAUTH-BOOKSHARE #{__method__}"))
        code = request.params['code']
        opts = deep_symbolize(options.auth_token_params)
        prms = token_params.to_hash(symbolize_keys: true)
        ##prms[:redirect_uri] ||= url_escape(callback_url)
        #prms['redirect_uri'] ||= url_escape(callback_url)
        client.auth_code.get_token(code, prms, opts)
          .tap { |result| __debug { "#{dbg} => #{result.inspect}" } }
      end

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

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # current_user
      #
      # @return [User]
      # @return [nil]
      #
      def current_user
        request&.env['warden']&.user
      end

      # configured_access_token
      #
      # @param [String] id            User ID.
      #
      # @return [::OAuth2::AccessToken]
      # @return [nil]                 If *id* is not valid.
      #
      def configured_access_token(id)
        abort "#{__method__} not valid" unless defined?(CONFIGURED_AUTH)
        hash = CONFIGURED_AUTH[id]
        ::OAuth2::AccessToken.from_hash(client, hash) if hash.present?
      end

      # configured_auth_hash
      #
      # @param [String] id            Bookshare user identity (email address).
      #
      # @return [OmniAuth::AccessToken]
      # @return [nil]                 If *id* is not valid.
      #
      def configured_auth_hash(id)
        abort "#{__method__} not valid" unless defined?(CONFIGURED_AUTH)
        return unless (atoken = configured_access_token(id)).present?
        AuthHash.new(provider: name, uid: id).tap do |hash|
          hash.uid   = uid
          hash.info  = info  unless skip_info?
          hash.extra = extra if extra
          hash.credentials = {
            token:         atoken.token,
            expires:       (expires = atoken.expires?),
            expires_at:    (atoken.expires_at    if expires),
            refresh_token: (atoken.refresh_token if expires)
          }.compact.stringify_keys
        end
      end

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Generate an auth hash based on fixed information.
      #
      # @param [String] id            Bookshare user identity (email address).
      #
      # @return [OmniAuth::AccessToken]
      #
      def self.configured_auth_hash(id)
        abort "#{__method__} not valid" unless defined?(CONFIGURED_AUTH)
        hash = {
          provider: 'bookshare',
          uid:      id,
          info: {
            first_name: '',
            last_name:  '',
            email:      id
          },
          credentials: {
            token:   CONFIGURED_AUTH[id][:access_token],
            expires: false
          }
        }.deep_stringify_keys
        AuthHash.new(hash)
      end

    end

  end

end

__loading_end(__FILE__)
