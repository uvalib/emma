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
  # :section: Exceptions
  # ===========================================================================

  protected

  # Wrap an exception or response in a service error.
  #
  # @param [Exception, Faraday::Response] obj
  #
  # @return [IngestService::ResponseError]
  #
  # This method overrides:
  # @see ApiService::Common#response_error
  #
  def response_error(obj)
    IngestService::ResponseError.new(obj)
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
