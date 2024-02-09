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
  SEND_DATA_OPT = %i[filename type disposition status].freeze

  # Send a copy of a file downloaded from Internet Archive.
  #
  # @param [String]       url
  # @param [Boolean, nil] new_tab     If *true* show in a new browser tab.
  # @param [Hash]         opt         To IaDownloadService#download, except
  #                                     #SEND_DATA_OPT to #send_data.
  #
  # @raise [ExecError]                @see IaDownloadService#download
  #
  # @return [void]
  #
  def ia_download_response(url, new_tab: false, **opt)
    dl_opt = opt.slice!(*SEND_DATA_OPT)
    name, type, data = ia_download_api.download(url, **dl_opt)
    return if data.blank?
    opt[:type]     ||= type
    opt[:filename] ||= name
    case new_tab
      when true  then opt[:disposition]   = 'attachment'
      when false then opt[:disposition]   = 'inline'
      else            opt[:disposition] ||= 'inline'
    end
    send_data(data, opt)
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
