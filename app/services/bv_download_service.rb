# app/services/bv_download_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Acquire files from the AWS S3 UVALIB-hosted BiblioVault collections.
#
class BvDownloadService < ApiService

  DESTRUCTIVE_TESTING = false

  include BvDownloadService::Properties
  include BvDownloadService::Action
  include BvDownloadService::Common
  include BvDownloadService::Definition
  include BvDownloadService::Status

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # @!method instance
    #   @return [BvDownloadService]
    # @!method update
    #   @return [BvDownloadService]
    class << self
    end

    # :nocov:
  end

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
    super
  end

end

__loading_end(__FILE__)
