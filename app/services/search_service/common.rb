# app/services/search_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchService::Common
#
module SearchService::Common

  include ApiService::Common

  include SearchService::Properties

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
  # @return [(Hash,Hash,String)]      Message body plus headers for GET.
  # @return [(Hash,Hash,Hash)]        Query plus headers for PUT, POST, PATCH.
  #
  def api_headers(params = nil, headers = nil, body = nil)
    super.tap do |prms, _hdrs, _body|
      prms.replace(build_query_options(prms)) unless update_request?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Include the shared data structure which holds the definition of the API
  # requests and parameters.
  #
  # @param [Module] base
  #
  def self.included(base)
    base.send(:include, SearchService::Definition)
  end

end

__loading_end(__FILE__)
