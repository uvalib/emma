# app/controllers/concerns/ia_download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for downloads from Internet Archive (including
# items held there on behalf of ACE/ScholarsPortal).
#
module IaDownloadConcern

  extend ActiveSupport::Concern

  include ActionController::DataStreaming

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # ia_download_api
  #
  # @return [IaDownloadService]
  #
  def ia_download_api
    # noinspection RubyMismatchedReturnType
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

  # Check for availability of a download from Internet Archive.  If the file
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

  # Send a copy of a file downloaded from Internet Archive.
  #
  # This should only be invoked after #ia_download_probe indicates that the
  # requested content file has been generated.
  #
  # @param [String]         identifier  IA item identifier.
  # @param [Symbol, String] type        Requested file type.
  # @param [Boolean, nil]   new_tab     If *true* show in a new browser tab.
  # @param [Hash]           opt         To IaDownloadService#download, except
  #                                       #SEND_DATA_OPT to #send_data.
  #
  # @raise [ExecError]                @see IaDownloadService#download
  #
  # @return [void]
  #
  def ia_download_retrieval(identifier:, type:, new_tab: false, **opt)
    send_opt = opt.extract!(*SEND_DATA_OPT)
    opt.merge!(identifier: identifier, type: type)
    name, mime, data = ia_download_api.download(**opt)
    return if data.blank?
    send_opt[:type]        ||= mime
    send_opt[:filename]    ||= name
    send_opt[:disposition] ||= new_tab ? 'attachment' : 'inline'
    send_data(data, send_opt)
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
