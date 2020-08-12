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
    #--
    # noinspection LongLine
    #++
    class Bookshare < OmniAuth::Strategies::OAuth2

      include Emma::Json
      include Emma::Debug

=begin
      include OmniAuth::Strategy

      def self.inherited(subclass)
        OmniAuth::Strategy.included(subclass)
      end
=end

      args %i[client_id client_secret]

      option :name,          name.split('::').last.to_s.underscore
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
      # @param [*] app The application on which this middleware is applied.
      #
      # @overload new(app, options = {})
      #   If nothing but a hash is supplied, initialized with the supplied
      #   options overriding the strategy's default options via a deep merge.
      #
      # @overload new(app, *args, options = {})
      #   If the strategy has supplied custom arguments that it accepts, they
      #   will be passed through and set to the appropriate values.
      #
      # @yield [Options] Yields options to block for further configuration.
      #
      # This method overrides:
      # @see OmniAuth::Strategy#initialize
      #
      # rubocop:disable UnusedMethodArgument
      def initialize(app, *args, &block)
        @app = app
        @env = nil
        @options = self.class.default_options.dup

        options.deep_merge!(args.pop) if args.last.is_a?(Hash)
        options[:name] ||= self.class.to_s.split('::').last.downcase

        self.class.args.each do |arg|
          break if args.empty?
          options[arg] = args.shift
        end

        # Make sure that all of the args have been dealt with, otherwise error.
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
      # This method overrides:
      # @see OmniAuth::Strategy#log
      #
      # == Implementation Notes
      # Instead of attempting to  override Configuration#default_logger this
      # override simply manages its own logger instance
      #
      def log(level, message)
        @log ||= Log.new(STDERR)
        @log.add(Log.log_level(level)) { "omniauth: (#{name}) #{message}" }
      end

=begin
      # Duplicates this instance and runs #call! on it.
      #
      # @param [Hash] The Rack environment.
      #
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
      #
      def call!(env) # rubocop:disable CyclomaticComplexity, PerceivedComplexity
        unless env['rack.session']
          error = 'You must provide a session to use OmniAuth.'
          error = OmniAuth::NoSessionError.new(error)
          raise(error)
        end

        @env = env
        @env['omniauth.strategy'] = self if on_auth_path?

        if OmniAuth.config.test_mode
          mock_call!(env)
        elsif on_auth_path? && options_request?
          options_call
        elsif on_request_path? && OmniAuth.config.allowed_method?(request)
          request_call
        elsif on_callback_path?
          callback_call
        elsif respond_to?(:other_phase)
          other_phase
        else
          @app.call(env)
        end
      end
=end

=begin
      # Responds to an OPTIONS request.
      #
      # @return [Array<(Integer, Hash, Array<String>)>]
      #
      def options_call
        OmniAuth.config.before_options_phase&.call(env)
        verbs = OmniAuth.config.allowed_request_methods
        verbs = verbs.map { |v| v.to_s.upcase }.join(', ')
        [200, { 'Allow' => verbs }, []]
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
        session['omniauth.params'] = params = normalize_parameters(request)
        __debug_items(dbg, "#{request.request_method}") do
          { options: options, session: __debug_session_hash }
        end

        # noinspection RubyResolve
        if params.key?(:commit)
          log :info, 'By-passing request_phase (local developer uid/token)'
          authorize_params # Generate session['omniauth.state']
          callback_call

        elsif current_user
          log :info, 'By-passing request_phase (configured uid/token)'
          authorize_params # Generate session['omniauth.state']
          callback_call

        elsif options.form.respond_to?(:call)
          log :info, 'Rendering form from supplied Rack endpoint.'
          options.form.call(env)

        elsif options.form
          log :info, 'Rendering form from underlying application.'
          call_app!

        elsif options.origin_param
          org = request.params[options.origin_param].presence
          ref = env['HTTP_REFERER'].presence
          ref = nil if ref&.end_with?(request_path)
          if org || ref
            log :info, "Origin from #{org ? 'request.params' : 'HTTP_REFERER'}"
          end
          session['omniauth.origin'] = org ||= ref
          __debug_line(dbg) { "session['omniauth.origin'] = #{org.inspect}" }
          request_phase

        else
          request_phase
        end
      end

      # Performs the steps necessary to run the callback phase of a strategy.
      #
      # This method overrides:
      # @see OmniAuth::Strategy#callback_call
      #
      def callback_call
        __debug { "OMNIAUTH #{__method__}" }
        super
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
        __debug((dbg = "OMNIAUTH-BOOKSHARE #{__method__}"))
        setup_phase
        log :info, 'MOCK - Request phase initiated.'

        # Store query params from the request URL extracted in #callback_phase.
        session['omniauth.params'] = request.get? ? request.GET : request.POST
        OmniAuth.config.before_request_phase&.call(env)

        __debug_items(dbg, "#{request.request_method}") do
          { options: options, session: __debug_session_hash }
        end

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
      def current_path
        @current_path ||=
          request.path_info.downcase.sub(CURRENT_PATH_REGEX, EMPTY_STRING)
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
            uri = URI.parse(request.url.remove(/\?.*$/))
            uri.path = ''
            # sometimes the url is actually showing http inside rails because
            # the other layers (like nginx) have handled the ssl termination.
            uri.scheme = 'https' if ssl? # rubocop:disable BlockNesting
            uri.to_s
          else
            ''
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
        env['omniauth.error']          = exception
        env['omniauth.error.type']     = message_key.to_sym
        env['omniauth.error.strategy'] = self
        message = "Authentication failure! #{message_key}"
        message +=
          if exception
            ": #{exception.class}, #{exception.message}"
          else
            ' encountered.'
          end
        log :error, message
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
        (request.env['HTTPS'] == 'on') ||
          (request.env['HTTP_X_FORWARDED_SSL'] == 'on') ||
          (request.env['HTTP_X_FORWARDED_SCHEME'] == 'https') ||
          (request.env['HTTP_X_FORWARDED_PROTO']&.split(',')[0] == 'https') ||
          (request.env['rack.url_scheme'] == 'https')
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
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#client
      #
      def client
        # noinspection RubyResolve
        @client ||=
          ::OAuth2::Client.new(
            options.client_id,
            options.client_secret,
            deep_symbolize(options.client_options)
          ).tap do |result|
            result.options[:redirect_uri] ||= callback_url.sub(/\?.*/, '')
            __debug { "OMNIAUTH-BOOKSHARE #{__method__} => #{result.inspect}" }
          end
      end

      # request_phase
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # @see ::OAuth2::ClientExt#request
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#request_phase
      #
      def request_phase
        OmniAuth.config.before_request_phase&.call(env)
        dbg  = "OMNIAUTH-BOOKSHARE #{__method__} | #{request.request_method}"
        __debug(dbg)
        code = client.auth_code
        prms = authorize_params
        url  = code.authorize_url(prms)
        __debug { "#{dbg} => authorize_url = #{url.inspect}" }
        redirect(url)
      end

      # authorize_params
      #
      # @return [Hash]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#authorize_params
      #
      def authorize_params
        super.tap do |result|
          __debug { "OMNIAUTH-BOOKSHARE #{__method__} => #{result.inspect}" }
        end
      end

      # token_params
      #
      # @return [Hash]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#token_params
      #
      def token_params
        super.tap do |result|
          __debug { "OMNIAUTH-BOOKSHARE #{__method__} => #{result.inspect}" }
        end
      end

      # callback_phase
      #
      # @raise [OmniAuth::Strategies::OAuth2::CallbackError]
      # @raise [OAuth2::Error]
      # @raise [Timeout::Error]
      # @raise [Errno::ETIMEDOUT]
      # @raise [SocketError]
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#callback_phase
      #
      #--
      # noinspection RubyScope
      #++
      def callback_phase
        __debug((dbg = "OMNIAUTH-BOOKSHARE #{__method__}"))
        # noinspection RubyUnusedLocalVariable
        result = error = nil
        params = request.params.reject { |_, v| v.blank? }
        error  = params['error_reason'] || params['error']

        # Raise an exception if the response indicated an error.
        if error
          description = params['error_description'] || params['error_reason']
          raise CallbackError.new(error, description, params['error_uri'])
        end

        # Raise an exception if the returned state doesn't match.
        # noinspection RubyResolve
        unless options.provider_ignores_state
          unless params['state'] == session.delete('omniauth.state')
            error = :csrf_detected
            raise CallbackError.new(error, 'CSRF detected')
          end
        end

        # noinspection RubyStringKeysInHashInspection
        result =
          if (op = normalize_parameters).key?(:commit)
            # Special case for locally-provided uid/token causes a redirect to
            # the special endpoint for direct token sign-in.
            self.access_token        = synthetic_access_token(op)
            session['omniauth.auth'] = synthetic_auth_hash(op)
            [302, { 'Location' => '/users/sign_in_as' }, []]

          elsif (username = current_user&.uid)
            # Special case for a fixed user causes a redirect to the special
            # endpoint for direct sign-in.
            self.access_token        = synthetic_access_token(username)
            session['omniauth.auth'] = synthetic_auth_hash(username)
            [302, { 'Location' => "/users/sign_in_as?id=#{username}" }, []]

          else
            # Normal case results in a call to the remote service.
            self.access_token = build_access_token
            self.access_token = access_token.refresh! if access_token.expired?
            env['omniauth.auth'] = auth_hash
            call_app!

          end

      rescue ::OAuth2::Error, CallbackError => error
        __debug_line(dbg) { ['INVALID', error.class, error.message] }
        error ||= :invalid_credentials

      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => error
        __debug_line(dbg) { ['TIMEOUT', error.class, error.message] }
        error = :timeout

      rescue ::SocketError => error
        __debug_line(dbg) { ['CONNECT', error.class, error.message] }
        error = :failed_to_connect

      rescue => error
        __debug_line(dbg) { ['EXCEPTION', error.class, error.message] }

      ensure
        fail!(error, error) if error
        return result
      end

      # =======================================================================
      # :section: OmniAuth::Strategies::OAuth2 overrides
      # =======================================================================

      protected

      # Acquire the OAuth token from the remote service.
      #
      # @return [::OAuth2::AccessToken]
      #
      # This method overrides:
      # @see OmniAuth::Strategies::OAuth2#build_access_token
      #
      def build_access_token
        __debug((dbg = "OMNIAUTH-BOOKSHARE #{__method__}"))
        code = request.params['code']
        prms = token_params.to_hash(symbolize_keys: true)
        # noinspection RubyResolve
        opts = deep_symbolize(options.auth_token_params)
        client.auth_code.get_token(code, prms, opts)
          .tap { |result| __debug { "#{dbg} => #{result.inspect}" } }
      end

=begin
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
=end

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

      # normalize_parameters
      #
      # @param [ActionController::Parameters, Hash, Rack::Request, nil] params
      #
      # @return [Hash{Symbol=>*}]
      #
      def normalize_parameters(params = nil)
        if params
          self.class.normalize_parameters(params)
        else
          env['omniauth.params'] || {}
        end
      end

      # Generate an access token based on fixed information.
      #
      # @param [::OAuth2::AccessToken, ActionController::Parameters, Hash, String] id
      #
      # @return [::OAuth2::AccessToken, nil]
      #
      # == Variations
      #
      # @overload synthetic_access_token(atoken)
      #   @param [::OAuth2::AccessToken] atoken
      #
      # @overload synthetic_access_token(id)
      #   @param [String] id          Bookshare user identity (email address).
      #
      # @overload synthetic_access_token(params)
      #   @param [ActionController::Parameters, Hash] params
      #   @option params [String] :uid
      #   @option params [String] :id             Alias for :uid.
      #   @option params [String] :access_token
      #   @option params [String] :token          Alias for :access_token.
      #
      #--
      # noinspection RubyYardParamTypeMatch
      #++
      def synthetic_access_token(id)
        token = hash = nil
        case id
          when ::OAuth2::AccessToken
            token  = id
          when String
            hash   = self.class.stored_auth[id]
          else
            params = normalize_parameters(id)
            token  = params[:access_token] || params[:token]
        end
        return token if token.is_a?(::OAuth2::AccessToken)
        return unless token.present? || hash.present?
        hash ||= self.class.stored_auth_entry(token)
        ::OAuth2::AccessToken.from_hash(client, hash)
      end

      # Generate an auth hash based on fixed information.
      #
      # @param [ActionController::Parameters, Hash, String] id
      # @param [String, nil]                                token
      #
      # @return [OmniAuth::AuthHash, nil]
      #
      # == Variations
      #
      # @overload synthetic_auth_hash(id, token = nil)
      #   @param [String] id          Bookshare user identity (email address).
      #   @param [String] token       Default from #stored_auth.
      #
      # @overload synthetic_auth_hash(params)
      #   @param [ActionController::Parameters, Hash] params
      #   @option params [OmniAuth::AuthHash] :auth
      #   @option params [String] :uid
      #   @option params [String] :id             Alias for :uid.
      #   @option params [String] :access_token
      #   @option params [String] :token          Alias for :access_token.
      #
      #--
      # noinspection RubyYardParamTypeMatch, RubyYardReturnMatch
      #++
      def synthetic_auth_hash(id, token = nil)
        if token.is_a?(::OAuth2::AccessToken)
          atoken = token
        elsif token.is_a?(String)
          atoken = synthetic_access_token(token: token)
        elsif id.is_a?(OmniAuth::AuthHash)
          return id
        elsif id.is_a?(String)
          atoken = synthetic_access_token(id)
        elsif (prm = normalize_parameters(id))[:auth].is_a?(OmniAuth::AuthHash)
          return prm[:auth]
        else
          id     = prm[:uid] || prm[:id]
          atoken = synthetic_access_token(prm)
        end
        abort "#{__method__}: id must be a string" unless id.is_a?(String)
        return unless atoken.present?
        OmniAuth::AuthHash.new(
          provider:    name,
          uid:         id,
          info:        { email: id }.compact.stringify_keys,
          credentials: {
            token:         atoken.token,
            expires:       (expires = atoken.expires?),
            expires_at:    (atoken.expires_at    if expires),
            refresh_token: (atoken.refresh_token if expires)
          }.compact.stringify_keys
        )
      end

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      public

      # normalize_parameters
      #
      # @param [ActionController::Parameters, Hash, Rack::Request, nil] params
      #
      # @return [Hash{Symbol=>*}]
      #
      #--
      # noinspection RubyNilAnalysis
      #++
      def self.normalize_parameters(params)
        params = params.params      if params.respond_to?(:params)
        params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
        params ||= {}
        params.symbolize_keys
      end

      # Generate an auth hash based on fixed information.
      #
      # @param [ActionController::Parameters, Hash, String] id
      # @param [String, nil]                                token
      #
      # @return [OmniAuth::AuthHash, nil]
      #
      # == Variations
      #
      # @overload synthetic_auth_hash(id, token = nil)
      #   @param [String] id          Bookshare user identity (email address).
      #   @param [String] token       Default from #stored_auth.
      #
      # @overload synthetic_auth_hash(params)
      #   @param [ActionController::Parameters, Hash] params
      #   @option params [OmniAuth::AuthHash] :auth
      #   @option params [String] :uid
      #   @option params [String] :id             Alias for :uid.
      #   @option params [String] :access_token
      #   @option params [String] :token          Alias for :access_token.
      #
      #--
      # noinspection RubyYardParamTypeMatch
      #++
      def self.synthetic_auth_hash(id, token = nil)
        if token.present?
          abort "#{__method__}: id must be a string" unless id.is_a?(String)
        elsif id.is_a?(OmniAuth::AuthHash)
          return id
        elsif id.is_a?(String)
          # Lookup token below.
        elsif (prm = normalize_parameters(id))[:auth].is_a?(OmniAuth::AuthHash)
          return prm[:auth]
        else
          id    = prm[:uid]          || prm[:id]
          token = prm[:access_token] || prm[:token] # or lookup token below
        end
        token ||= stored_auth.dig(id, :access_token)
        OmniAuth::AuthHash.new(
          provider:    default_options[:name],
          uid:         id,
          info:        { email: id }.stringify_keys,
          credentials: { token: token, expires: false }.stringify_keys
        )
      end

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      public

      # A table of pre-authorized user/token pairs for development purposes.
      #
      # @type [Hash{String=>String}]
      #
      CONFIGURED_AUTH =
        safe_json_parse(BOOKSHARE_TEST_USERS, default: {}).deep_freeze

      # Table of user names/tokens acquired for use in non-production deploys.
      #
      # Token are taken from the User table entries that have an :access_token
      # value.  If BOOKSHARE_TEST_USERS is supplied, it is used to prime (or
      # update) database table.
      #
      # @return [Hash{String=>Hash}]
      #
      # == Usage Notes
      # Because the logic is only performed once, direct changes to the User
      # table will not be reflected here, however changes made indirectly via
      # #stored_auth_update will change both the value returned by this method
      # and the associated User table entry.
      #
      def self.stored_auth
        @@stored_auth ||=
          begin
            if (entries = CONFIGURED_AUTH).present?
              tokens = entries.values.map { |v| { access_token: v } }
              User.update(entries.keys, tokens)
            end
            User.where.not(access_token: nil).map { |u|
              [u.email, stored_auth_entry(u.access_token)]
            }.to_h
          end
      end

      # Add or update a user name/token entry.
      #
      # If input parameters were invalid then no change will be made.
      #
      # @param [OmniAuth::AuthHash, String]         uid
      # @param [String, ::OAuth2::AccessToken, nil] token
      #
      # @return [Hash{String=>Hash}]  The updated set of saved user/tokens.
      #
      # == Variations
      #
      # @overload stored_auth_update(auth)
      #   @param [OmniAuth::AuthHash]            auth   User/token to add
      #
      # @overload stored_auth_update(auth)
      #   @param [String]                        uid    User to add.
      #   @param [String, ::OAuth2::AccessToken] token  Associated token.
      #
      def self.stored_auth_update(uid, token = nil)
        if (auth = uid).is_a?(OmniAuth::AuthHash)
          uid, token = [auth.uid, auth.credentials.token]
        elsif (atoken = token).is_a?(::OAuth2::AccessToken)
          # noinspection RubyNilAnalysis
          token = atoken.token
        end

        if uid.blank? || token.blank?
          Log.warn do
            msg = %W(#{__method__}: missing)
            msg << 'uid'   if uid.blank?
            msg << 'and'   if uid.blank? && token.blank?
            msg << 'token' if token.blank?
            msg.join(' ')
          end
          return
        end

        # Create or update the dynamic table entry.
        if stored_auth[uid].blank?
          # noinspection RubyYardParamTypeMatch
          stored_auth[uid] = stored_auth_entry(token)
        elsif stored_auth[uid][:access_token] != token
          stored_auth[uid][:access_token] = token
        else
          token = nil
        end

        # Update the database table if there was a change.
        if token
          User.find_or_create_by(email: uid) { |u| u.access_token = token }
        end

        # Return with the relevant entry.
        stored_auth.slice(uid)
      end

      # Produce a stored_auth table entry value.
      #
      # @param [String] token
      #
      # @return [Hash{Symbol=>String}]
      #
      def self.stored_auth_entry(token)
        { access_token: token, token_type: 'bearer', scope: 'basic' }
      end

    end

  end

end

__loading_end(__FILE__)
