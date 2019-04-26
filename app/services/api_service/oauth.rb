# app/services/api_service/oauth.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class ApiService

  # Authentication and authorization.
  #
  #
  # Two-step authorization code grant flow:
  # @see https://apidocs-qa.bookshare.org/auth/index.html#sample-authorization-code-flow
  #
  # One-step implicit grant flow:
  # @see https://apidocs-qa.bookshare.org/auth/index.html#sample-implicit-flow
  #
  # Password grant flow:
  # @see https://apidocs-qa.bookshare.org/auth/index.html#password-grant
  #
  module Oauth

    include Common

    # @type [Hash{Symbol=>String}]
    OAUTH_SEND_MESSAGE = {

      # TODO: e.g.:
      no_items:      'There were no items to request',
      failed:        'Unable to request items right now',

    }.reverse_merge(API_SEND_MESSAGE).freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    OAUTH_SEND_RESPONSE = {

      # TODO: e.g.:
      no_items:       'no items',
      failed:         nil

    }.reverse_merge(API_SEND_RESPONSE).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @return [String]
    attr_reader :access_token

    # @return [String]
    attr_reader :refresh_token

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the session is authorized.
    #
    def authorized?
      access_token.present?
    end

    # set_authorization_code
    #
    # @param [String, Hash] data
    #
    # @return [void]
    #
    def set_authorization_code(data)
      if data.is_a?(Hash)
        code  = data[:code]
        state = data[:state] # TODO: ???
      else
        code  = data
        state = nil
      end
      resp = get_token(type: 'authorization_code', code: code.to_s)
      if resp.is_a?(ApiOauthToken)
        @access_token  = resp.access_token
        @refresh_token = resp.refresh_token
      else
        Log.error { "unexpected Bookshare response: #{resp.pretty_inspect}" }
      end
    end

    # set_token
    #
    # @param [Hash, String] params
    #
    # @return [ApiOauthToken]
    # @return [ApiOauthTokenError]
    # @return [nil]
    #
    def set_token(params)
      unless params.is_a?(Hash)
        params =
          params.to_s.split('&').map { |kv|
            parts = kv.split('=')
            k = parts.shift.to_sym
            v = parts.join('=')
            [k, v]
          }.to_h
      end
      if params[:access_token].present?
        ApiOauthToken.new(params).tap do |result|
          @access_token  = result.access_token.presence
          @refresh_token = result.refresh_token.presence
        end
      elsif params[:error].present?
        ApiOauthTokenError.new(params)
      else
        Log.warn { "#{__method__}: unexpected params: #{params.inspect}" }
      end
    end

    # generate_token
    #
    # @param [Api::AuthType] auth
    #
    # @return [void]
    #
    def generate_token(auth = AUTH_TYPE, grant = GRANT_TYPE)
      $stderr.puts "### #{__method__} auth=#{auth.inspect} grant=#{grant.inspect}" # TODO: remove
      resp = @access_token = @refresh_token = nil
      case grant
        when 'authorization_code', 'refresh_token'
          resp = get_authorization(auth)
          case resp
            when ApiStatusModel
              resp = nil if auth == 'code'
            when ApiOauthToken
              if auth == 'token'
                code = resp.access_token # TODO: ???
                @access_token =
                  code.to_s.split('#').last.to_s.split('&').find do |kv|
                    k, v = kv.split('=')
                    v if k == 'access_token'
                  end
                resp = nil
              end
          end
        when 'password'
          resp = get_token(type: grant)
          if resp.is_a?(ApiOauthToken)
            @access_token = resp.access_token.presence
            resp = nil
          end
        else
          Log.error { "#{__method__}: unexpected: #{grant} grant type" }
          resp = nil
      end
      if resp.is_a?(ApiOauthTokenError)
        refreshing = (grant == 'refresh_token')
        expiration = (resp.error_description =~ /^Access token expired/)
        generate_token(auth, 'refresh_token') if expiration && !refreshing
      elsif resp
        Log.error { "unexpected Bookshare response: #{resp.pretty_inspect}" }
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_authorization
    #
    # @param [Api::AuthType] type
    #
    # @return [ApiStatusModel]        If *type* == 'code'
    # @return [ApiOauthToken]         If *type* == 'token'
    # @return [ApiOauthTokenError]
    #
    # @see https://apidocs-qa.bookshare.org/auth/index.html#_oauth-authorize
    #
    def get_authorization(type = AUTH_TYPE)
      $stderr.puts "### #{__method__} type=#{type.inspect}" # TODO: remove
      params = {
        response_type: type,
        client_id:     API_KEY,
        redirect_uri:  "#{@callback_url}/auth/callback", # TODO: ???
        scope:         'basic',
        state:         'state_value' # TODO: ???
      }
      oauth_response = oauth('authorize',  params)
      data = oauth_response&.body&.presence
      if !oauth_response&.success?
        $stderr.puts "--- #{__method__} | ApiOauthTokenError | data = #{data.inspect.truncate(256)}" # TODO: remove
        ApiOauthTokenError.new(data, error: @exception)
      elsif type == 'token'
        $stderr.puts "--- #{__method__} | ApiOauthToken | data = #{data.inspect.truncate(256)}" # TODO: remove
        ApiOauthToken.new(data, error: @exception)
      else
        $stderr.puts "--- #{__method__} | ApiStatusModel | data = #{data.inspect.truncate(256)}" # TODO: remove
        ApiStatusModel.new(data, format: :xml, error: @exception)
      end
        .tap { |result| $stderr.puts "<<< #{__method__} result = #{result.inspect}" } # TODO: remove
    end

    # get_token
    #
    # @param [Api::GrantType] type
    # @param [String]         code      From `get_authorization.access_token`
    # @param [String]         refresh   From original request
    # @param [String]         user      For *type* == 'password'
    # @param [String]         password  For *type* == 'password'
    #
    # @return [ApiMyAccountSummary]
    #
    # @see https://apidocs-qa.bookshare.org/auth/index.html#_oauth-token
    #
    def get_token(
      type:     GRANT_TYPE,
      code:     nil,
      refresh:  nil,
      user:     nil,
      password: nil
    )
      $stderr.puts "### #{__method__} type=#{type.inspect}" # TODO: remove
      params = {
        grant_type: type,
        scope:      'basic'
      }
      case type
        when 'authorization_code'
          params[:code] = code
        when 'refresh_token'
          params[:refresh_token] = refresh || @refresh_token
        when 'password'
          params[:username] = user     || USERNAME
          params[:password] = password || PASSWORD
        else
          Log.error { "#{__method__}: unexpected: #{type} grant type" }
      end
      oauth_response = oauth('token',  params)
      data = oauth_response&.body&.presence
      if oauth_response&.success?
        $stderr.puts "--- #{__method__} | ApiOauthToken | data = #{data.inspect}" # TODO: remove
        ApiOauthToken.new(data, error: @exception)
      else
        $stderr.puts "--- #{__method__} | ApiOauthTokenError | data = #{data.inspect}" # TODO: remove
        ApiOauthTokenError.new(data, error: @exception)
      end
        .tap { |result| $stderr.puts "<<< #{__method__} result = #{result.inspect}" } # TODO: remove
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # raise_exception
    #
    # @param [Symbol, String] method  For log messages.
    #
    # This method overrides:
    # @see ApiService::Common#raise_exception
    #
    def raise_exception(method)
      response_table = OAUTH_SEND_RESPONSE
      message_table  = OAUTH_SEND_MESSAGE
      message = request_error_message(method, response_table, message_table)
      raise Api::AuthError, message
    end

  end

end

__loading_end(__FILE__)
