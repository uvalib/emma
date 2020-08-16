# app/services/ingest_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IngestService::Common
#
module IngestService::Common

  include ApiService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, IngestService::Definition)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Validate the presence of these values required for the full interactive
  # instance of the application.
  required_env_vars(:INGEST_BASE_URL, :INGEST_API_KEY)

  # The URL for the API connection.
  #
  # @return [String]
  #
  def base_url
    @base_url ||= INGEST_BASE_URL
  end

  # Federated Ingest API key.
  #
  # @return [String]
  #
  def api_key
    INGEST_API_KEY
  end

  # API version is not a part of request URLs.
  #
  # @return [nil]
  #
  def api_version
    # INGEST_API_VERSION
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Send an API request.
  #
  # @param [Symbol]            verb
  # @param [String]            action
  # @param [Hash, String, nil] params
  # @param [Hash, nil]         headers
  # @param [Hash]              opt
  #
  # @option opt [Boolean]      :no_redirect
  # @option opt [Integer, nil] :redirection
  #
  # @raise [ApiService::EmptyResultError]
  # @raise [ApiService::HtmlResultError]
  # @raise [ApiService::RedirectionError]
  # @raise [ApiService::Error]
  #
  # @return [Faraday::Response]
  # @return [nil]
  #
  # This method overrides:
  # @see ApiService::Common#transmit
  #
  def transmit(verb, action, params, headers, **opt)
    super.tap do |response|
      if response.is_a?(Faraday::Response)
        # noinspection RubyCaseWithoutElseBlockInspection
        case response.status
          when 202
            # NOTE: *May* erroneously be the status for some bad conditions.
            if response.body.present?
              __debug { "INGEST: HTTP 202 with body #{response.body.inspect}" }
              raise response_error(response)
            end
          when 207
            # Partial success implies partial failure:
            __debug { "INGEST: HTTP 207 with body #{response.body.inspect}" }
            raise response_error(response)
        end
      end
    end
  end

end

__loading_end(__FILE__)
