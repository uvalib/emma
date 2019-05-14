# lib/ext/oauth2/lib/oauth2/access_token.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the OAuth2 gem.

__loading_begin(__FILE__)

require 'oauth2/access_token'

module OAuth2

  module AccessTokenExt

=begin
    attr_reader :client, :token, :expires_in, :expires_at, :params
    attr_accessor :options, :refresh_token
=end

=begin
    class << self
      # Initializes an AccessToken from a Hash
      #
      # @param [Client] the OAuth2::Client instance
      # @param [Hash] a hash of AccessToken property values
      # @return [AccessToken] the initalized AccessToken
      def from_hash(client, hash)
        hash = hash.dup
        new(client, hash.delete('access_token') || hash.delete(:access_token), hash)
      end

      # Initializes an AccessToken from a key/value application/x-www-form-urlencoded string
      #
      # @param [Client] client the OAuth2::Client instance
      # @param [String] kvform the application/x-www-form-urlencoded string
      # @return [AccessToken] the initalized AccessToken
      def from_kvform(client, kvform)
        from_hash(client, Rack::Utils.parse_query(kvform))
      end
    end
=end

    # Initalize an AccessToken
    #
    # @param [Client] client the OAuth2::Client instance
    # @param [String] token the Access Token value
    # @param [Hash] opts the options to create the Access Token with
    # @option opts [String] :refresh_token (nil) the refresh_token value
    # @option opts [FixNum, String] :expires_in (nil) the number of seconds in which the AccessToken will expire
    # @option opts [FixNum, String] :expires_at (nil) the epoch time in seconds in which AccessToken will expire
    # @option opts [Symbol] :mode (:header) the transmission mode of the Access Token parameter value
    #    one of :header, :body or :query
    # @option opts [String] :header_format ('Bearer %s') the string format to use for the Authorization header
    # @option opts [String] :param_name ('access_token') the parameter name to use for transmission of the
    #    Access Token value in :body or :query transmission mode
    def initialize(client, token, opts = {}) # rubocop:disable Metrics/AbcSize
=begin
      @client = client
      @token = token.to_s
      opts = opts.dup
      [:refresh_token, :expires_in, :expires_at].each do |arg|
        instance_variable_set("@#{arg}", opts.delete(arg) || opts.delete(arg.to_s))
      end
      @expires_in ||= opts.delete('expires')
      @expires_in &&= @expires_in.to_i
      @expires_at &&= @expires_at.to_i
      @expires_at ||= Time.now.to_i + @expires_in if @expires_in
      @options = {:mode          => opts.delete(:mode) || :header,
                  :header_format => opts.delete(:header_format) || 'Bearer %s',
                  :param_name    => opts.delete(:param_name) || 'access_token'}
      @params = opts
=end
      super
      $stderr.puts "ACCESS_TOKEN #{__method__} | #{self.inspect}"
    end

=begin
    # Indexer to additional params present in token response
    #
    # @param [String] key entry key to Hash
    def [](key)
      @params[key]
    end
=end

=begin
    # Whether or not the token expires
    #
    # @return [Boolean]
    def expires?
      !!@expires_at
    end
=end

=begin
    # Whether or not the token is expired
    #
    # @return [Boolean]
    def expired?
      expires? && (expires_at < Time.now.to_i)
    end
=end

    # Refreshes the current Access Token
    #
    # @return [AccessToken] a new AccessToken
    # @note options should be carried over to the new AccessToken
    def refresh!(params = {})
=begin
      raise('A refresh_token is not available') unless refresh_token
      params[:grant_type] = 'refresh_token'
      params[:refresh_token] = refresh_token
      new_token = @client.get_token(params)
      new_token.options = options
      new_token.refresh_token = refresh_token unless new_token.refresh_token
      new_token
=end
      super.tap { |result|
        $stderr.puts "ACCESS_TOKEN #{__method__} => #{result.inspect}"
      }
    end

=begin
    # Convert AccessToken to a hash which can be used to rebuild itself with AccessToken.from_hash
    #
    # @return [Hash] a hash of AccessToken property values
    def to_hash
      params.merge(:access_token => token, :refresh_token => refresh_token, :expires_at => expires_at)
    end
=end

    # Make a request with the Access Token
    #
    # @param [Symbol] verb the HTTP request method
    # @param [String] path the HTTP URL path of the request
    # @param [Hash] opts the options to make the request with
    # @see Client#request
    def request(verb, path, opts = {}, &block)
      configure_authentication!(opts)
      $stderr.puts "ACCESS_TOKEN #{__method__} | #{verb} #{path.inspect} | opts = #{opts.inspect}"
      @client.request(verb, path, opts, &block)
    end

=begin
    # Make a GET request with the Access Token
    #
    # @see AccessToken#request
    def get(path, opts = {}, &block)
      request(:get, path, opts, &block)
    end

    # Make a POST request with the Access Token
    #
    # @see AccessToken#request
    def post(path, opts = {}, &block)
      request(:post, path, opts, &block)
    end

    # Make a PUT request with the Access Token
    #
    # @see AccessToken#request
    def put(path, opts = {}, &block)
      request(:put, path, opts, &block)
    end

    # Make a PATCH request with the Access Token
    #
    # @see AccessToken#request
    def patch(path, opts = {}, &block)
      request(:patch, path, opts, &block)
    end

    # Make a DELETE request with the Access Token
    #
    # @see AccessToken#request
    def delete(path, opts = {}, &block)
      request(:delete, path, opts, &block)
    end
=end

=begin
    # Get the headers hash (includes Authorization token)
    def headers
      {'Authorization' => options[:header_format] % token}
    end
=end

  private

    # configure_authentication!
    #
    # @param [Hash] opts
    #
    # @return [void]
    #
    # This method overrides:
    # @see OAuth2::AccessToken#configure_authentication!
    #
    def configure_authentication!(opts)
      opts[:params] ||= {}
      opts[:params][:api_key] = @client.id
      super
=begin
      case options[:mode]
        when :header
          opts[:headers] ||= {}
          opts[:headers].merge!(headers)
        when :query
          opts[:params] ||= {}
          opts[:params][options[:param_name]] = token
          opts[:params][:api_key] = @client.options[:client_id]
        when :body
          opts[:body] ||= {}
          if opts[:body].is_a?(Hash)
            opts[:body][options[:param_name]] = token
            opts[:body][:api_key] = @client.options[:client_id]
          else
            opts[:body] << "&#{options[:param_name]}=#{token}"
            opts[:body] << "&api_key=#{@client.options[:client_id]}"
          end
        else
          raise("invalid :mode option of #{options[:mode]}")
      end
=end
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override OAuth2::AccessToken => OAuth2::AccessTokenExt

__loading_end(__FILE__)
