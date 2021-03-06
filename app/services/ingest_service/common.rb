# app/services/ingest_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IngestService::Common
#
module IngestService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  # @private
  #
  def self.included(base)
    base.send(:include, IngestService::Definition)
  end

  include ApiService::Common
  include IngestService::Properties

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  protected

  # The ingest service actually takes its API key via headers.
  #
  # @param [Hash, nil] params         Default: @params.
  #
  # @return [Hash]                    New API parameters.
  #
  def api_options(params = nil)
    super.except!(:api_key)
  end

  # Add API key header.
  #
  # @param [Hash, nil]         params   Default: @params.
  # @param [Hash, nil]         headers  Default: {}.
  # @param [String, Hash, nil] body     Default: nil unless `#update_request?`.
  #
  # @return [(String,Hash)]           Message body plus headers for GET.
  # @return [(Hash,Hash)]             Query plus headers for PUT, POST, PATCH.
  #
  def api_headers(params = nil, headers = nil, body = nil)
    params, headers, body = super
    # noinspection RubyNilAnalysis
    headers = headers.merge('X-API-Key' => api_key)
    return params, headers, body
  end

  # ===========================================================================
  # :section: ApiService::Common overrides
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
