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
      include OmniAuth::ExtensionDebugging

      # =======================================================================
      # :section: Configuration
      # =======================================================================

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
      option :revoke_path,            '/users/sign_out'

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
      def raw_info
        @raw_info ||=
          access_token.get("#{BOOKSHARE_BASE_URL}/me").parsed
            .deep_symbolize_keys
      end

      # =======================================================================
      # :section: OmniAuth::Strategy overrides
      # =======================================================================

      public

      # Direct access to the OmniAuth logger, automatically prefixed with this
      # strategy's name.
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
      # @return [(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)]
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

      # =======================================================================
      # :section: OmniAuth::Strategies::OAuth2 overrides
      # =======================================================================

      public

      # The OAuth2 client instance.
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
      #
      # @see ::OAuth2::ClientExt#request
      #
      def request_phase
        __ext_debug((req = request.request_method))
        code = client.auth_code
        prms = authorize_params
        url  = code.authorize_url(prms)
        __ext_debug(req) { { authorize_url: url } }
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
      # @return [(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)]
      #
      #--
      # noinspection RubyScope, RubyStringKeysInHashInspection
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
            [302, { 'Location' => '/users/sign_in_as' }, []]

          elsif (username = current_uid)
            # Special case for a fixed user causes a redirect to the special
            # endpoint for direct sign-in.
            self.access_token        = synthetic_access_token(username)
            session['omniauth.auth'] = synthetic_auth_hash(username)
            [302, { 'Location' => "/users/sign_in_as?id=#{username}" }, []]

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
      def build_access_token
        __ext_debug
        code = request.params['code']
        prms = token_params.to_hash(symbolize_keys: true)
        # noinspection RubyResolve
        opts = deep_symbolize(options.auth_token_params)
        client.auth_code.get_token(code, prms, opts)
          .tap { |result| __ext_debug("--> #{result.inspect}") }
      end

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # The strategy was called outside of the request sequence.
      #
      # The only current use-case is token revocation, which causes a POST to
      # the OAuth2 token revocation endpoint, but in all cases the method
      # continues on with the rest of the call stack.
      #
      # @see OmniAuth::Strategy#call!
      #
      def other_phase
        __ext_debug("current_path    = #{current_path.inspect}")
        __ext_debug("revoke_path     = #{revoke_path.inspect}")
        __ext_debug("on_revoke_path? = #{on_revoke_path?}")
        if on_revoke_path?
          if !application_deployed?
            __ext_debug('NOT REVOKING TOKEN ON localhost')

          elsif debug_user?
            __ext_debug("NOT REVOKING TOKEN FOR #{current_uid}")

          elsif false?(url_parameters[:revoke])
            __ext_debug('NOT REVOKING TOKEN DUE TO revoke=false PARAMETER')

          elsif current_token.blank?
            __ext_debug('NOT REVOKING TOKEN - NO TOKEN')

          else
            __ext_debug("REVOKING TOKEN #{current_token.inspect}")
            revoke_access_token
          end
          session.delete('omniauth.auth')
        end
        app.call(env)
      end

      # Indicate whether the current request is for token revocation.
      #
      def on_revoke_path?
        on_path?(revoke_path)
      end

      # The request path indicating a token revocation.
      #
      # @return [String]
      #
      def revoke_path
        @revoke_path ||=
          options[:revoke_path] || "#{path_prefix}/#{name}/revoke"
      end

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # Terminate the session with the OAuth2 provider telling it to revoke the
      # access token.
      #
      # @param [OAuth2::AccessToken, nil] token   Default: `#access_token`.
      #
      # @return [OAuth2::Response]
      # @return [nil]                 If no token was given or present.
      #
      def revoke_access_token(token = nil)
        entry = 'Token revocation'
        entry = "#{entry} for #{token.inspect}" if token
        if (token ||= access_token)
          log :info, entry
          client.auth_code.revoke_token(token)
        else
          Log.warn { "#{__method__}: no token given" }
        end
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

      # The user name of the currently signed-in user.
      #
      # @return [String]
      # @return [nil]
      #
      def current_uid
        current_user&.uid
      end

      # Indicate whether the user is one is capable of short-circuiting the
      # authorization process.
      #
      # @param [String, nil] uid      Default: `#current_uid`
      #
      def debug_user?(uid = nil)
        session['debug'].present? && self.class.debug_user?(uid || current_uid)
      end

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # Normalize URL parameters from the item or *request* if none was given.
      #
      # @param [ActionController::Parameters, Hash, Rack::Request, nil] params
      #
      # @return [Hash{Symbol=>*}]
      #
      def url_parameters(params = nil)
        self.class.url_parameters(params || request)
      end

      # Retrieve the token from :access_token or from "omniauth.auth".
      #
      # @return [String, nil]
      #
      def current_token
        access_token&.token || session['omniauth.auth']
      end

      # Generate an access token based on fixed information.
      #
      # @param [::OAuth2::AccessToken, ActionController::Parameters, Hash, String] src
      #
      # @return [::OAuth2::AccessToken, nil]
      #
      # == Variations
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
      # noinspection RubyYardParamTypeMatch
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
        entry ||= token && self.class.stored_auth_entry(token)
        ::OAuth2::AccessToken.from_hash(client, entry) if entry.present?
      end

      # Generate an auth hash based on fixed information.
      #
      # @param [ActionController::Parameters, OmniAuth::AuthHash, Hash, String] src
      #
      # @return [OmniAuth::AuthHash, nil]
      #
      # == Variations
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
      # noinspection RubyYardParamTypeMatch, RubyYardReturnMatch
      #++
      def synthetic_auth_hash(src)
        if src.is_a?(OmniAuth::AuthHash)
          return src
        elsif src.is_a?(String)
          uid   = src
          token = synthetic_access_token(src)
        elsif (params = url_parameters(src))[:auth].is_a?(OmniAuth::AuthHash)
          return params[:auth]
        else
          uid   = params[:uid] || params[:id]
          token = synthetic_access_token(params)
        end
        if uid && !uid.is_a?(String)
          Log.warn("#{__method__}: invalid id: #{uid.inspect}")
        end
        return unless uid.is_a?(String) && token.is_a?(::OAuth2::AccessToken)
        OmniAuth::AuthHash.new(
          provider:    name,
          uid:         uid,
          info:        { email: uid }.stringify_keys,
          credentials: {
            token:         token.token,
            expires:       (expires = token.expires?),
            expires_at:    (token.expires_at    if expires),
            refresh_token: (token.refresh_token if expires)
          }.compact.stringify_keys
        )
      end

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      public

      # Normalize URL parameters.
      #
      # @param [ActionController::Parameters, Hash, Rack::Request, nil] params
      #
      # @return [Hash{Symbol=>*}]
      #
      #--
      # noinspection RubyNilAnalysis, RubyYardParamTypeMatch
      #++
      def self.url_parameters(params)
        params = params.params      if params.respond_to?(:params)
        params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
        params.is_a?(Hash) ? reject_blanks(params.deep_symbolize_keys) : {}
      end

      # Generate an auth hash based on fixed information.
      #
      # @param [ActionController::Parameters, OmniAuth::AuthHash, Hash, String] src
      # @param [String, nil] token
      #
      # @return [OmniAuth::AuthHash, nil]
      #
      # == Variations
      #
      # @overload synthetic_auth_hash(uid, token = nil)
      #   @param [String] uid         Bookshare user identity (email address).
      #   @param [String] token       Default from #stored_auth.
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
      # noinspection RubyYardParamTypeMatch
      #++
      def self.synthetic_auth_hash(src, token = nil)
        if token.present?
          uid = src
        elsif src.is_a?(OmniAuth::AuthHash)
          return src
        elsif src.is_a?(String)
          uid = src
        elsif (p = url_parameters(src))[:auth].is_a?(OmniAuth::AuthHash)
          return p[:auth]
        else
          uid = p[:uid] || p[:id]
          token = p[:access_token] || p[:token] || p.dig(:credentials, :token)
        end
        if uid && !uid.is_a?(String)
          Log.warn("#{__method__}: invalid uid: #{uid.inspect}")
        end
        token ||= stored_auth.dig(uid, :access_token)
        return unless uid.is_a?(String) && token.is_a?(String)
        OmniAuth::AuthHash.new(
          provider:    default_options[:name],
          uid:         uid,
          info:        { email: uid }.stringify_keys,
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
        reject_blanks(safe_json_parse(BOOKSHARE_TEST_USERS)).tap { |entries|
          if entries.present? && rails_application?
            users  = entries.keys
            tokens = entries.values.map { |v| { access_token: v } }
            User.update(users, tokens)
          end
        }.deep_freeze

      # Table of user names/tokens acquired for use in non-production deploys.
      #
      # Token are taken from the User table entries that have an :access_token
      # value.  If BOOKSHARE_TEST_USERS is supplied, it is used to prime (or
      # update) database table.
      #
      # @param [Boolean] refresh      If *true*, re-read the database.
      #
      # @return [Hash{String=>Hash}]
      #
      # == Usage Notes
      # Because the logic is only performed once, direct changes to the User
      # table will not be reflected here, however changes made indirectly via
      # #stored_auth_update will change both the value returned by this method
      # and the associated User table entry.
      #
      #--
      # noinspection RubyClassVariableUsageInspection
      #++
      def self.stored_auth(refresh = false)
        @@stored_auth = nil if refresh
        @@stored_auth ||=
          User.where.not(access_token: nil).map { |u|
            [u.email, stored_auth_entry(u.access_token)]
          }.to_h
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

      # =======================================================================
      # :section: Class methods
      # =======================================================================

      public

      # Indicate whether the user is one that is capable of short-circuiting
      # the authorization process by using a stored token.
      #
      # @param [*] uid
      #
      def self.debug_user?(uid)
        stored_auth.key?(uid)
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
        # @return [*]
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

        # =====================================================================
        # :section:
        # =====================================================================

        protected

        # Terminate the session with the OAuth2 provider telling it to revoke
        # the access token.
        #
        # @param [OAuth2::AccessToken, nil] token   Default: `#access_token`.
        #
        # @return [OAuth2::Response]
        # @return [nil]               If no token was given or present.
        #
        def revoke_access_token(token = nil)
          __ext_debug(*token)
          super
        end

      end

      override Bookshare => BookshareDebug

    end

  end

end

__loading_end(__FILE__)
