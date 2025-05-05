# app/controllers/concerns/bv_download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for retrieval of EMMA publisher collection items
# stored on AWS S3.
#
# Currently, there is only one collection (:bibliovault_ump) but future
# collections will use the same logic.
#
module BvDownloadConcern

  extend ActiveSupport::Concern

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA publisher collections retrieval service.
  #
  # @return [BvDownloadService]
  #
  def bv_download_api
    # noinspection RubyMismatchedReturnType
    api_service(BvDownloadService)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Options for ActionController::DataStreaming#send_data
  #
  # @type [Array<Symbol>]
  #
  SEND_DATA_OPT = %i[filename disposition status].freeze

  # Send a copy of an item from an EMMA publisher collection.
  #
  # @param [String] url               Original S3 item URL.
  # @param [Hash]   opt               Passed to BvDownloadService#api_download.
  #
  # @return [void]                    Results written into `response`.
  #
  def bv_download_retrieval(url:, **opt)
    opt.slice!(*SEND_DATA_OPT, *BvDownloadService::API_DOWNLOAD_OPT)
    opt[:filename] ||= url.split('/').last
    opt[:meth]     ||= __method__
    bv_download_api.api_download(response, url: url, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    include RepositoryHelper

  end

end

__loading_end(__FILE__)
