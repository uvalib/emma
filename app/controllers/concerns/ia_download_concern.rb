# app/controllers/concerns/ia_download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for retrieval of items from Internet Archive
# (including items held there on behalf of ACE/ScholarsPortal).
#
module IaDownloadConcern

  extend ActiveSupport::Concern

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the Internet Archive retrieval service.
  #
  # @return [IaDownloadService]
  #
  def ia_download_api
    api_service(IaDownloadService)
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

  # Check for availability of a retrieval from Internet Archive.  If the file
  # requires on-the-fly generation, this will be triggered here.
  #
  # @param [String]         identifier  IA item identifier.
  # @param [Symbol, String] type        Requested file type.
  # @param [Hash]           opt         To IaDownloadService#probe
  #
  # @return [Hash]
  #
  def ia_download_probe(identifier:, type:, **opt)
    opt.except!(*SEND_DATA_OPT)
    opt.merge!(identifier: identifier, type: type)
    ia_download_api.probe(**opt)
  end

  # Send a copy of a file retrieved from Internet Archive.
  #
  # This should only be invoked after #ia_download_probe indicates that the
  # requested content file has been generated.
  #
  # @param [String]         identifier  IA item identifier.
  # @param [Symbol, String] type        Requested file type.
  # @param [Hash]           opt         Passed to #api_download.
  #
  # @return [void]
  #
  def ia_download_retrieval(identifier:, type:, **opt)
    opt.slice!(*SEND_DATA_OPT, *IaDownloadService::API_DOWNLOAD_OPT)
    opt.merge!(identifier: identifier, type: type)
    opt[:meth] ||= __method__
    ia_download_api.api_download(response, **opt)
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
