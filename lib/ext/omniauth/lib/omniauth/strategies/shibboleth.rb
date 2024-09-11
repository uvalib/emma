# lib/ext/omniauth/lib/omniauth/strategies/shibboleth.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Overrides for OmniAuth::Strategies::Shibboleth.

__loading_begin(__FILE__)

module OmniAuth

  module Strategies

    # This strategy is based on 'omniauth-shibboleth' but with #callback_phase
    # refactored to minimize log output.
    #
    class Shibboleth

      include OmniAuth::Strategy
      include OmniAuth::ExtensionDebugging

      # =======================================================================
      # :section: Configuration
      # =======================================================================

      # This is the value expected by Devise.
      option :request_path, '/users/auth/shibboleth'

      # This is the value expected by Devise.
      # This path should be hijacked by the Apache module for Shibboleth.
      option :callback_path, '/users/auth/shibboleth/callback'

      option :fields, %w[
        cn
        givenName
        mail
        physicalDeliveryOffice
        sn
        telephoneNumber
      ]

      # =======================================================================
      # :section: OmniAuth::Strategy overrides
      # =======================================================================

      public

      # The request phase results in a redirect to a path that is configured to
      # be hijacked by mod rewrite and shibboleth apache module.
      #
      # @return [(Integer, Rack::Headers, Rack::BodyProxy)]
      # @return [(Integer, Hash{String=>any,nil}, Array<String>)]
      #
      def request_phase
        redirect options.callback_path
      end

      # callback_phase
      #
      # @raise [Timeout::Error]
      # @raise [Errno::ETIMEDOUT]
      # @raise [SocketError]
      #
      # @return [Array(Integer, Rack::Headers, Rack::BodyProxy)]
      # @return [Array(Integer, Hash{String=>any,nil},   Array<String>)]
      #
      def callback_phase
        raise 'No request' unless request
        if (eppn = request.env['HTTP_EPPN'].to_s).include?('@')
          @uid = eppn
        elsif (aff = request.env['HTTP_AFFILIATION'])
          @uid = parse_affiliation(aff)&.find { _1.start_with?('member@') }
        else
          @uid = ''
        end
        if @uid.present?
          log :debug, "Success env: #{request_env.inspect}"
        elsif @uid.nil?
          log :error, "Failure 1 env: #{request_env.inspect}"
          @uid = 'unknown@unknown'
          raise 'Missing header EPPN'
        else
          # The Apache module and rewrite probably haven't been properly setup.
          log :error, "Failure 2 env: #{request_env.inspect}"
          @uid = 'unknown@unknown'
          raise 'Shibboleth likely has not been set up properly'
        end
        super
      end

      # User login name.
      #
      # @return [String]
      #
      #--
      # noinspection RubyMismatchedReturnType
      #++
      def uid
        @uid
      end

      # User account details.
      #
      # @return [Hash]
      #
      def info
        req_env = request_env
        options.fields.map { |field|
          names = [field.upcase, field.underscore.upcase].uniq
          value = names.map { req_env["HTTP_#{_1}"] }.compact.first
          [field.to_sym, value]
        }.to_h
      end

      # Extra information.
      #
      # @return [Hash]
      #
      def extra
        req_env        = request_env
        affiliations   = parse_affiliation(req_env['HTTP_AFFILIATION'])
        affiliations ||= inferred_affiliations
        affiliations ||= parse_member(req_env['HTTP_MEMBER'])
        { affiliations: affiliations }
      end

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # Return just the potentially-useful parts of `request.env`.
      #
      # This also converts the "(null)" value set by the Apache module to an
      # actual *nil*.
      #
      # @return [Hash{String=>any,nil}]
      #
      def request_env
        request.env.select { |k, v|
          case v
            when nil, true, false, String, Symbol, Numeric
              !k.start_with?('rack', 'action_dispatch')
          end
        }.transform_values { |v|
          v = v.strip if v.is_a?(String)
          v unless v == '(null)'
        }
      end

      # parse_affiliation
      #
      # @param [Array, String, nil] value
      #
      # @return [Array<String>, nil]
      #
      def parse_affiliation(value)
        value = value.join(';')               if value.is_a?(Array)
        value.strip.split(/\s*;\s*/).presence if value.is_a?(String)
      end

      # parse_member
      #
      # @param [Array, String, nil] value
      #
      # @return [Array<String>, nil]
      #
      def parse_member(value)
        value = value.join(';')               if value.is_a?(Array)
        value.strip.split(/\s*;\s*/).presence if value.is_a?(String)
      end

      # inferred_affiliations
      #
      # @return [Array<String>, nil]
      #
      def inferred_affiliations
        [@uid.gsub(/^[^@]+/, 'member')] if @uid.is_a?(String)
      end

    end

  end

end

__loading_end(__FILE__)
