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
        __auth_debug(__method__)
        setup_phase
        log :info, 'Request phase initiated.'

        # Store query params to be passed back via #callback_call.
        session['omniauth.params'] = params = normalize_parameters(request)
        __auth_debug(__method__, "#{request.request_method}") do
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
          __auth_debug(__method__) { { "session['omniauth.origin']": org } }
          request_phase

        else
          request_phase
        end
      end

      # Performs the steps necessary to run the callback phase of a strategy.
      #
      def callback_call
        __auth_debug(__method__)
        super
      end if DEBUG_OAUTH

      # call_app!
      #
      # @return [*]
      #
      def call_app!(env = @env)
        __auth_debug(__method__) { env }
        super
      end if DEBUG_OAUTH

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
            __auth_debug(__method__, "=> #{result.inspect}")
          end
      end

      # request_phase
      #
      # @return [(Integer, Rack::Utils::HeaderHash, Rack::BodyProxy)]
      #
      # @see ::OAuth2::ClientExt#request
      #
      def request_phase
        OmniAuth.config.before_request_phase&.call(env)
        __auth_debug(__method__, (req = request.request_method))
        code = client.auth_code
        prms = authorize_params
        url  = code.authorize_url(prms)
        __auth_debug(__method__, req) { { authorize_url: url } }
        redirect(url)
      end

      # authorize_params
      #
      # @return [Hash]
      #
      def authorize_params
        super.tap do |result|
          __auth_debug(__method__, "=> #{result.inspect}")
        end
      end if DEBUG_OAUTH

      # token_params
      #
      # @return [Hash]
      #
      def token_params
        super.tap do |result|
          __auth_debug(__method__, "=> #{result.inspect}")
        end
      end if DEBUG_OAUTH

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
      # noinspection RubyScope
      #++
      def callback_phase
        __auth_debug(__method__)
        result = nil
        params = request.params.reject { |_, v| v.blank? }
        e_type = params['error_reason'] || params['error']

        # Raise an exception if the response indicated an error.
        if e_type
          description = params['error_description'] || params['error_reason']
          raise CallbackError.new(e_type, description, params['error_uri'])
        end

        # Raise an exception if the returned state doesn't match.
        # noinspection RubyResolve
        unless options.provider_ignores_state
          unless params['state'] == session.delete('omniauth.state')
            e_type = :csrf_detected
            raise CallbackError.new(e_type, 'CSRF detected')
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
        __auth_debug(__method__, 'INVALID', error.class, error.message)
        e_type ||= :invalid_credentials

      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => error
        __auth_debug(__method__, 'TIMEOUT', error.class, error.message)
        e_type = :timeout

      rescue ::SocketError => error
        __auth_debug(__method__, 'CONNECT', error.class, error.message)
        e_type = :failed_to_connect

      rescue => error
        __auth_debug(__method__, 'EXCEPTION', error.class, error.message)
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
        __auth_debug(__method__)
        code = request.params['code']
        prms = token_params.to_hash(symbolize_keys: true)
        # noinspection RubyResolve
        opts = deep_symbolize(options.auth_token_params)
        client.auth_code.get_token(code, prms, opts).tap do |result|
          __auth_debug(__method__, "=> #{result.inspect}")
        end
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
      # :section: Debugging
      # =======================================================================

      public

      if not DEBUG_OAUTH

        def __auth_debug(*); end

      else

        include Emma::Debug::OutputMethods

        # Debug method for the including class.
        #
        # @param [String, Symbol] meth
        # @param [Array]          args
        # @param [Hash]           opt
        # @param [Proc]           block   Passed to #__debug_items.
        #
        # @return [nil]
        #
        def __auth_debug(meth, *args, **opt, &block)
          opt[:leader]      = 'OMNIAUTH-BOOKSHARE'
          opt[:separator] ||= ' | '
          __debug_items(meth, *args, opt, &block)
        end

      end

    end

  end

end

__loading_end(__FILE__)
