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
  SEND_DATA_OPTIONS = %i[filename type disposition status].freeze

  # Send a copy of a file downloaded from Internet Archive.
  #
  # @param [String]       url
  # @param [Boolean, nil] new_tab     If *true* show in a new browser tab.
  # @param [Hash]         opt         To IaDownloadService#download, except
  #                                     #SEND_DATA_OPTIONS to #send_data.
  #
  # @raise [ExecError]                @see IaDownloadService#download
  #
  # @return [void]
  #
  def ia_download_response(url, new_tab: false, **opt)
    send_opt = opt.extract!(:filename, :type, :disposition, :status)
    name, type, data = ia_download_api.download(url, **opt)
    return if data.blank?
    send_opt[:type]     ||= type
    send_opt[:filename] ||= name
    case new_tab
      when true  then send_opt[:disposition]   = 'attachment'
      when false then send_opt[:disposition]   = 'inline'
      else            send_opt[:disposition] ||= 'inline'
    end
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
