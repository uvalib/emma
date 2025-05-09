# app/services/ia_download_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Acquire files from Internet Archive
#
class IaDownloadService < ApiService

  DESTRUCTIVE_TESTING = false

  include IaDownloadService::Properties
  include IaDownloadService::Action
  include IaDownloadService::Common
  include IaDownloadService::Definition
  include IaDownloadService::Status

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION

    # @!method instance
    #   @return [IaDownloadService]
    # @!method update
    #   @return [IaDownloadService]
    class << self
    end

  end
  # :nocov:

  # ===========================================================================
  # :section: ApiService overrides
  # ===========================================================================

  public

  # Initialize a new instance
  #
  # @param [User, nil]   user
  # @param [String, nil] base_url     Base URL to the external service (instead
  #                                     of #BASE_URL defined by the subclass).
  # @param [Hash]        opt          Stored in @options
  #
  def initialize(user: nil, base_url: nil, **opt)
    opt[:params_encoder] ||= Faraday::IaParamsEncoder
    super
  end

end

__loading_end(__FILE__)
