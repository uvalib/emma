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

    # An extension of the +OAuth2+ strategy which sets up some defaults that
    # would otherwise have to be specified in initializers/devise.rb.
    #
    # @see https://github.com/omniauth/omniauth-oauth2
    #
    # == Implementation Notes
    # The base implementation of #uid, #info, #credentials, and #extra and
    # their use of associated blocks within the class definition seem to be
    # problematic used in conjunction with retrieving account information from
    # +Bookshare+.  Thus, these methods are overridden explicitly in order to
    # ensure consistency.
    #
    #--
    # noinspection LongLine
    #++
    class Bookshare < OmniAuth::Strategies::OAuth2

      include Emma::Common
      include Emma::Json

      include OmniAuth::ExtensionDebugging

      # =======================================================================
      # :section: Configuration
      # =======================================================================

      args %i[client_id client_secret]

      # noinspection RubyMismatchedArgumentType
      option :name,          name&.demodulize&.to_s&.underscore
      # noinspection RubyMismatchedArgumentType
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

      # =======================================================================
      # :section: OmniAuth::Strategy overrides
      # =======================================================================

      public

      # Direct access to the OmniAuth logger, automatically prefixed with this
      # strategy's name.
      #
      # @param [Symbol] level
      # @param [String] message
      #
      # @return [nil]
      #
      # == Implementation Notes
      # Instead of attempting to override Configuration#default_logger this
      # override simply manages its own logger instance.
      #
      def log(level, message)
        @log ||= Log.new(STDERR)
        @log.add(Log.log_level(level)) { "omniauth: (#{name}) #{message}" }
      end

      # Performs the steps necessary to run the request phase of a strategy.
      #
      # @return [Array<(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)>]
      # @return [Array<(Integer, Hash{String=>*}, Array<String>)>]
      #
      def request_call
        __ext_debug
        setup_phase
        log :info, 'Request phase initiated.'

        # Store query params to be passed back via #callback_call.
        session['omniauth.params'] = url_parameters(request)
        __ext_debug("#{request.request_method}") do
          { options: options, session: __debug_session_hash }
        end
        OmniAuth.config.before_request_phase&.call(env)

        # noinspection RubyResolve
        if session['omniauth.params'].key?(:commit)
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
          origin  = request.params[options.origin_param].presence
          referer = env['HTTP_REFERER'].presence
          origin ||= (referer if referer && !referer.end_with?(request_path))
          session['omniauth.origin'] = origin if origin
          __ext_debug do
            { "session['omniauth.origin']" => session['omniauth.origin'] }
          end
          request_phase

        else
          request_phase
        end
      rescue error # TODO: remove - testing
        __debug_exception("#{__ext_class} #{__method__}", error)
        raise error
      end

      # User login name.
      #
      # @return [String]
      #
      def uid
        account_info[:username]&.to_s&.downcase || current_user&.uid
      end

      # User account details.
      #
      # @return [Hash]
      #
      def info
        {
          first_name: account_info.dig(:name, :firstName),
          last_name:  account_info.dig(:name, :lastName),
          email:      account_info[:username]
        }.compact_blank!
      end

      # Credential information for the authenticated user from #access_token.
      #
      # @return [Hash]
      #
      def credentials
        {
          token:         access_token.token,
          expires:       (expires = access_token.expires?),
          expires_at:    (access_token.expires_at    if expires),
          refresh_token: (access_token.refresh_token if expires)
        }.compact_blank!
      end

      # Extra information.
      #
      # @return [Hash, nil]           Currently always *nil*.
      #
      def extra
      end

      # Generate authorization information for the authenticated user.
      #
      # @return [OmniAuth::AuthHash]
      #
      def auth_hash
        data = {
          provider:    name,
          uid:         uid,
          info:        (info unless skip_info?),
          credentials: credentials,
          extra:       extra
        }.compact_blank!
        OmniAuth::AuthHash.new(data)
      end

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # Information about the user account.
      #
      # @return [Hash{Symbol=>Any}]
      #
      def account_info
        @account_info ||= get_account_info
      end

      # Acquire information about the user account from +Bookshare+.
      #
      # @param [Hash, nil] opt        Passed to ::OAuth2::AccessToken#get
      #
      # @return [Hash]
      #
      # == Implementation Notes
      # NOTE: Needs to relate to:
      # @see BookshareService::UserAccount#get_user_identity
      #
      # E.g.:
      #
      # !{
      #   username: 'john@smith.com',
      #   links: [],
      #   !{
      #     firstName: 'John',
      #     lastName:  'Smith',
      #     middle:    nil,
      #     prefix:    nil,
      #     suffix:    nil,
      #     links:     []
      #   }
      # }
      #
      def get_account_info(opt = nil)
        __ext_debug
        opt = { raise_errors: false }.merge!(opt || {})
        url = "#{BOOKSHARE_BASE_URL}/#{BOOKSHARE_API_VERSION}/me"
        rsp = access_token.get(url, opt)
        if (err = rsp.error)
          Log.warn { "#{__method__}: #{err.class} #{err.inspect}" }
          res = nil
        elsif !(res = rsp.parsed).is_a?(Hash)
          Log.warn { "#{__method__}: returned #{res.inspect}" }
          res = nil
        end
        res&.deep_symbolize_keys! || {}
      end

      # =======================================================================
      # :section: OmniAuth::Strategies::OAuth2 overrides
      # =======================================================================

      public

      # The +OAuth2+ client instance.
      #
      # @return [::OAuth2::Client]
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
            __ext_debug("--> #{result.inspect}")
          end
      end

      # request_phase
      #
      # @return [(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)]
      # @return [(Integer, Hash{String=>*}, Array<String>)]
      #
      # @see ::OAuth2::ClientExt#request
      #
      def request_phase
        __ext_debug((req = request.request_method))
        code = client.auth_code
        prms = authorize_params
        url  = code.authorize_url(prms)
        __ext_debug(req) { { authorize_url: url } }
        # noinspection RubyMismatchedReturnType
        redirect(url)
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
      # @return [Array<(Integer, Hash{String=>*}, Array<String>)>]
      #
      #--
      # noinspection RubyScope
      #++
      def callback_phase
        __ext_debug
        result = nil
        params = url_parameters(request)
        e_type = params[:error_reason] || params[:error]

        # Raise an exception if the response indicated an error.
        if e_type
          desc = params[:error_description] || params[:error_reason]
          raise CallbackError.new(params[:error], desc, params[:error_uri])
        end

        # Raise an exception if the returned state doesn't match.
        # noinspection RubyResolve
        unless options.provider_ignores_state
          state = params[:state]
          if state.blank? || (state != session.delete('omniauth.state'))
            e_type = :csrf_detected
            raise CallbackError.new(e_type, 'CSRF detected')
          end
        end

        original_params = url_parameters(env['omniauth.params'])
        result =
          if original_params.key?(:commit)
            # Special case for locally-provided uid/token causes a redirect to
            # the special endpoint for direct token sign-in.
            self.access_token        = synthetic_access_token(original_params)
            session['omniauth.auth'] = synthetic_auth_hash(original_params)
            call_redirect('/users/sign_in_as', params: original_params)

          elsif (username = current_user&.uid)
            # Special case for a fixed user causes a redirect to the special
            # endpoint for direct sign-in.
            self.access_token        = synthetic_access_token(username)
            session['omniauth.auth'] = synthetic_auth_hash(username)
            call_redirect("/users/sign_in_as?id=#{username}")

          else
            # Normal case results in a call to the remote service.
            self.access_token = build_access_token
            self.access_token = access_token.refresh! if access_token.expired?
            # Can't call *super* -- have to perform the actions of
            # OmniAuth::Strategy#callback_phase manually here:
            env['omniauth.auth'] = auth_hash
            call_app!

          end

      rescue ::OAuth2::Error, CallbackError => error
        __ext_debug('INVALID', error.class, error.message)
        e_type ||= :invalid_credentials

      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => error
        __ext_debug('TIMEOUT', error.class, error.message)
        e_type = :timeout

      rescue ::SocketError => error
        __ext_debug('CONNECT', error.class, error.message)
        e_type = :failed_to_connect

      rescue => error
        __ext_debug('EXCEPTION', error.class, error.message)
        e_type = :unexpected_error

      ensure
        fail!(e_type, error) if e_type || error
        re_raise_if_internal_exception(error)
        return result
      end

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # An alternative to call_app! which generates a response for a redirect.
      #
      # @param [String] location
      # @param [Hash]   log_extra
      #
      # @return [Array<(Integer, Hash{String=>*}, Array<String>)>]
      #
      #--
      # noinspection RubyStringKeysInHashInspection
      #++
      def call_redirect(location, **log_extra)
        __ext_debug do
          {
            location:        location,
            'omniauth.auth': session['omniauth.auth'],
            access_token:    access_token
          }.merge!(log_extra)
        end
        check_user_validity
        [302, { 'Location' => location }, []]
      end

      # Trigger an exception if the signed-in user doesn't have a valid
      # +Bookshare+ +OAuth2+ token.
      #
      # @raise [RuntimeError]   If +Bookshare+ account info was unavailable.
      #
      # @return [void]
      #
      def check_user_validity
        get_account_info(raise_errors: true)
      end

      # =======================================================================
      # :section: OmniAuth::Strategies::OAuth2 overrides
      # =======================================================================

      protected

      # Acquire the +OAuth2+ token from the remote service.
      #
      # @return [::OAuth2::AccessToken]
      #
      def build_access_token
        __ext_debug
        code = request.params['code']
        prms = token_params.to_hash(symbolize_keys: true)
        # noinspection RubyResolve
        opts = deep_symbolize(options.auth_token_params)
        # noinspection RubyMismatchedArgumentType
        client.auth_code.get_token(code, prms, opts)
          .tap { |result| __ext_debug("--> #{result.inspect}") }
      end

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # The currently signed-in user.
      #
      # @return [User]
      # @return [nil]
      #
      def current_user
        request&.env['warden']&.user
      end

      # Normalize URL parameters from the item or *request* if none was given.
      #
      # @param [ActionController::Parameters, Hash, Rack::Request, nil] params
      #
      # @return [Hash{Symbol=>Any}]
      #
      #--
      # noinspection RubyNilAnalysis
      #++
      def url_parameters(params = nil)
        params ||= request
        params   = params.params      if params.respond_to?(:params)
        params   = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
        params.is_a?(Hash) ? reject_blanks(params.deep_symbolize_keys) : {}
      end

      # Generate an access token based on fixed information.
      #
      # @param [::OAuth2::AccessToken, ActionController::Parameters, Hash, String] src
      #
      # @return [::OAuth2::AccessToken, nil]
      #
      #--
      # == Variations
      #++
      #
      # @overload synthetic_access_token(atoken)
      #   @param [::OAuth2::AccessToken] atoken
      #
      # @overload synthetic_access_token(uid)
      #   @param [String] uid         Bookshare user identity (email address).
      #
      # @overload synthetic_access_token(params)
      #   @param [ActionController::Parameters, Hash] params
      #   @option params [String] :uid
      #   @option params [String] :id             Alias for :uid.
      #   @option params [String] :access_token
      #   @option params [String] :token          Alias for :access_token.
      #
      #--
      # noinspection RubyMismatchedArgumentType
      #++
      def synthetic_access_token(src)
        entry = token = nil
        if src.is_a?(String)
          entry = self.class.stored_auth[src]
        elsif src.is_a?(::OAuth2::AccessToken)
          token = src
        elsif (p = url_parameters(src)).present?
          token = p[:access_token] || p[:token] || p.dig(:credentials, :token)
        end
        return token if token.is_a?(::OAuth2::AccessToken)
        entry ||= token && self.class.stored_auth_entry_value(token)
        ::OAuth2::AccessToken.from_hash(client, entry) if entry.present?
      end

      # Generate an auth hash based on fixed information.
      #
      # @param [String, ActionController::Parameters, OmniAuth::AuthHash, Hash] src
      #
      # @return [OmniAuth::AuthHash, nil]
      #
      #--
      # == Variations
      #++
      #
      # @overload synthetic_auth_hash(uid)
      #   @param [String] uid         Bookshare user identity (email address).
      #
      # @overload synthetic_auth_hash(auth_hash)
      #   @param [OmniAuth::AuthHash] auth_hash
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
      # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
      #++
      def synthetic_auth_hash(src)
        if src.is_a?(OmniAuth::AuthHash)
          return src
        elsif src.is_a?(String)
          user  = src
          token = synthetic_access_token(src)
        elsif (params = url_parameters(src))[:auth].is_a?(OmniAuth::AuthHash)
          return params[:auth]
        else
          user  = params[:uid] || params[:id]
          token = synthetic_access_token(params)
        end
        if user && !user.is_a?(String)
          Log.warn("#{__method__}: invalid id: #{user.inspect}")
        end
        return unless user.is_a?(String) && token.is_a?(::OAuth2::AccessToken)
        OmniAuth::AuthHash.new(
          provider:    name,
          uid:         user,
          info:        { email: user },
          credentials: {
            token:         token.token,
            expires:       (expires = token.expires?),
            expires_at:    (token.expires_at    if expires),
            refresh_token: (token.refresh_token if expires)
          }.compact
        )
      end

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      public

      # Create an AuthHash from the given source.
      #
      # @param [Hash, User] src
      #
      # @return [OmniAuth::AuthHash]
      #
      def self.auth_hash(src)
        # noinspection RailsParamDefResolve
        src  = src.try(:attributes)
        src  = src.try(:symbolize_keys) || {}
        cred = src.slice(:token, :expires, :expires_at, :refresh_token)
        info = src.slice(:email, :first_name, :last_name)
        data = src.slice(:provider, :uid, :info, :credentials)

        data[:credentials]           = (data[:credentials] || {}).merge(cred)
        data[:credentials][:token] ||= src[:access_token]
        data[:info]                  = (data[:info] || {}).merge(info)
        data[:info][:email]        ||= data[:uid]
        data[:uid]                 ||= data[:info][:email]
        data[:provider]            ||= default_options[:name]

        OmniAuth::AuthHash.new(reject_blanks(data))
      end

      # Generate an auth hash based on fixed information.
      #
      # @param [User, String, ActionController::Parameters, OmniAuth::AuthHash, Hash] src
      # @param [String, nil] token
      #
      # @return [OmniAuth::AuthHash, nil]
      #
      #--
      # == Variations
      #++
      #
      # @overload synthetic_auth_hash(uid, token = nil)
      #   @param [String, User] uid     Bookshare user identity (email address).
      #   @param [String]       token   Default from #stored_auth.
      #
      # @overload synthetic_auth_hash(auth_hash)
      #   @param [OmniAuth::AuthHash] auth_hash
      #
      # @overload synthetic_auth_hash(params)
      #   @param [ActionController::Parameters, Hash] params
      #   @option params [OmniAuth::AuthHash] :auth
      #   @option params [String] :uid
      #   @option params [String] :id             Alias for :uid.
      #   @option params [String] :access_token
      #   @option params [String] :token          Alias for :access_token.
      #
      def self.synthetic_auth_hash(src, token = nil)
        # noinspection RubyMismatchedReturnType
        return src if src.is_a?(OmniAuth::AuthHash)
        user = src.is_a?(String) ? src : src.try(:uid)
        if user.nil? && (src = url_parameters(src).presence).is_a?(Hash)
          return src[:auth] if src[:auth].is_a?(OmniAuth::AuthHash)
          user    = src[:uid] || src[:id]
          token ||= src[:access_token] || src[:token]
          token ||= src.dig(:credentials, :token)
        end
        # noinspection RubyMismatchedArgumentType
        if !user.is_a?(String)
          Log.warn("#{__method__}: invalid user: #{user.inspect}") if user
        elsif (token ||= stored_auth.dig(user, :access_token)).is_a?(String)
          auth_hash(uid: user, token: token, expires: false)
        end
      end

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      public

      # Table of user names/tokens acquired for use in non-production deploys.
      #
      # Token are taken from the User table entries that have an :access_token
      # value.  If BOOKSHARE_TEST_AUTH is supplied, it is used to prime (or
      # update) the database table.
      #
      # @param [Hash, nil] values
      #
      # @return [Hash{String=>Hash}]
      #
      # == Usage Notes
      # Because the logic is only performed once, direct changes to the User
      # table will not be reflected here, however changes made indirectly via
      # #stored_auth_update and/or #stored_auth_update_user will change both
      # the value returned by this method and the associated User table entry.
      #
      def self.stored_auth(values = nil)
        # noinspection RubyMismatchedReturnType, RubyMismatchedVariableType
        if values.is_a?(Hash)
          @stored_auth = values.deep_dup
        else
          @stored_auth ||= {}
        end
      end

      # Produce a stored_auth table entry value.
      #
      # @param [String] token
      #
      # @return [Hash{Symbol=>String}]
      #
      def self.stored_auth_entry_value(token)
        { access_token: token, token_type: 'bearer', scope: 'basic' }
      end

    end

    if DEBUG_OAUTH

      # Overrides adding extra debugging around method calls.
      #
      module BookshareDebug

        include OmniAuth::ExtensionDebugging

        # =====================================================================
        # :section: OmniAuth::Strategy overrides
        # =====================================================================

        # Performs the steps necessary to run the callback phase of a strategy.
        #
        def callback_call
          __ext_debug
          super
        end

        # call_app!
        #
        # @return [Any]
        #
        def call_app!(env = @env)
          __ext_debug { env }
          super
        end

        # =====================================================================
        # :section: OmniAuth::Strategies::OAuth2 overrides
        # =====================================================================

        public

        # authorize_params
        #
        # @return [Hash]
        #
        def authorize_params
          super
            .tap { |result| __ext_debug("--> #{result.inspect}") }
        end

        # token_params
        #
        # @return [Hash]
        #
        def token_params
          super
            .tap { |result| __ext_debug("--> #{result.inspect}") }
        end

      end

      override Bookshare => BookshareDebug

    end

  end

end

__loading_end(__FILE__)
