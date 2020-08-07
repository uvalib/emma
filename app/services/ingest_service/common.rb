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

  API_KEY      = INGEST_API_KEY
  BASE_URL     = INGEST_BASE_URL
  API_VERSION  = INGEST_API_VERSION

  # Validate the presence of these values required for the full interactive
  # instance of the application.
  if rails_application?
    Log.error('Missing INGEST_API_KEY')  unless API_KEY
    Log.error('Missing INGEST_BASE_URL') unless BASE_URL
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # API version is not a part of search URLs.
  #
  # @return [nil]
  #
  # This method overrides:
  # @see ApiService::Common#api_version
  #
  def api_version
    nil
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

  # ===========================================================================
  # :section: Exceptions
  # ===========================================================================

  protected

  # Wrap an exception or response in a service error.
  #
  # @param [Exception, Faraday::Response] obj
  #
  # @return [IngestService::Error]
  #
  # This method overrides:
  # @see ApiService::Common#response_error
  #
  def response_error(obj)
    IngestService::Error.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [IngestService::EmptyResultError]
  #
  # This method overrides:
  # @see ApiService::Common#empty_response_error
  #
  def empty_response_error(obj)
    IngestService::EmptyResultError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [IngestService::HtmlResultError]
  #
  # This method overrides:
  # @see ApiService::Common#html_response_error
  #
  def html_response_error(obj)
    IngestService::HtmlResultError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [IngestService::RedirectionError]
  #
  # This method overrides:
  # @see ApiService::Common#redirect_response_error
  #
  def redirect_response_error(obj)
    IngestService::RedirectionError.new(obj)
  end

end

__loading_end(__FILE__)
