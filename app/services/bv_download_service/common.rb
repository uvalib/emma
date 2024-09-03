# app/services/bv_download_service/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Service implementation methods.
#
module BvDownloadService::Common

  include ApiService::Common

  include BvDownloadService::Properties

  include AwsS3::Shared::AwsMethods

  # ===========================================================================
  # :section: ApiService::Common overrides
  # ===========================================================================

  public

  # Retrieve a copy of a file and download it to the browser.
  #
  # @param [ActionDispatch::Response] response  Client response object.
  # @param [String, nil]              url       Default: `#base_url`.
  # @param [Hash]                     opt       Passed to #stream_item.
  #
  # @return [void]
  #
  def api_download(response, url:, **opt)
    opt.except!(*API_DOWNLOAD_OPT)
    data = stream_item(url, **opt)
    response.write(data)
  end

  # ===========================================================================
  # :section: AwsS3::Shared::AwsMethods overrides
  # ===========================================================================

  public

  # Get an S3 client instance.
  #
  # @param [Hash] opt                 Passed to Aws::S3::Client#initialize
  #
  # @return [Aws::S3::Client]
  #
  def s3_client(**opt)
    opt.reverse_merge!(S3_OPTIONS)
    super
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
    base.include(BvDownloadService::Definition)
  end

end

__loading_end(__FILE__)
