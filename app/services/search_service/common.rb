# app/services/search_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Common
#
module SearchService::Common

  include ApiService::Common

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, SearchService::Definition)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  BASE_URL     = SEARCH_BASE_URL
  API_VERSION  = SEARCH_API_VERSION

  # Validate the presence of these values required for the full interactive
  # instance of the application.
  if rails_application?
    Log.error('Missing SEARCH_BASE_URL') unless BASE_URL
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

  # api_headers
  #
  # @param [Hash]         params      Default: @params.
  # @param [Hash]         headers     Default: {}.
  # @param [String, Hash] body        Default: *nil* unless `#update_request?`.
  #
  # @return [Array<(String,Hash)>]    Message body plus headers for GET.
  # @return [Array<(Hash,Hash)>]      Query plus headers for PUT, POST, PATCH.
  #
  # This method overrides:
  # @see ApiService::Common#api_headers
  #
  def api_headers(params = nil, headers = nil, body = nil)
    super.tap do |prms, _hdrs, _body|
      prms.replace(build_query_options(prms)) unless update_request?
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
  # @return [SearchService::ResponseError]
  #
  # This method overrides:
  # @see ApiService::Common#response_error
  #
  def response_error(obj)
    SearchService::ResponseError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [SearchService::EmptyResultError]
  #
  # This method overrides:
  # @see ApiService::Common#empty_response_error
  #
  def empty_response_error(obj)
    SearchService::EmptyResultError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [SearchService::HtmlResultError]
  #
  # This method overrides:
  # @see ApiService::Common#html_response_error
  #
  def html_response_error(obj)
    SearchService::HtmlResultError.new(obj)
  end

  # Wrap response in a service error.
  #
  # @param [Faraday::Response] obj
  #
  # @return [SearchService::RedirectionError]
  #
  # This method overrides:
  # @see ApiService::Common#redirect_response_error
  #
  def redirect_response_error(obj)
    SearchService::RedirectionError.new(obj)
  end

end

__loading_end(__FILE__)
