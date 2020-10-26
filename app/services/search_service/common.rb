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
  # :section: ApiService::Common overrides
  # ===========================================================================

  public

  # The URL for the API connection.
  #
  # @return [String]
  #
  # @see #SEARCH_BASE_URL
  #
  def base_url
    @base_url ||= SEARCH_BASE_URL
  end

  # An API key is not a part of search URLs.
  #
  # @return [nil]
  #
  def api_key
    nil
  end

  # API version is not a part of search URLs.
  #
  # @return [nil]
  #
  def api_version
    # SEARCH_API_VERSION
  end

  # ===========================================================================
  # :section: ApiService::Common overrides
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
  def api_headers(params = nil, headers = nil, body = nil)
    super.tap do |prms, _hdrs, _body|
      prms.replace(build_query_options(prms)) unless update_request?
    end
  end

end

__loading_end(__FILE__)
