# app/services/ia_download_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search'

# Acquire files from Internet Archive
#
class IaDownloadService < ApiService

  # Include send/receive modules from "app/services/ia_download_service/**.rb".
  include_submodules(self)

  # ===========================================================================
  # :section: ApiService overrides
  # ===========================================================================

  public

  # Initialize a new instance
  #
  # @param [User, nil]   user         User instance which includes a
  #                                     Bookshare user identity and token.
  # @param [String, nil] base_url     Base URL to the external service (instead
  #                                     of #BASE_URL defined by the subclass).
  # @param [Hash]        opt          Stored in @options
  #
  # This method overrides:
  # @see ApiService#initialize
  #
  def initialize(user: nil, base_url: nil, **opt)
    opt[:params_encoder] ||= Faraday::IaParamsEncoder
    super(user: user, base_url: base_url, **opt)
  end

end

__loading_end(__FILE__)
