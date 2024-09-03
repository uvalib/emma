# app/services/ia_download_service/action/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods which support acquiring a record from Internet Archive
# "Printdisabled Unencrypted Ebook API" endpoints.
#
module IaDownloadService::Action::Records

  include IaDownloadService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Check for availability of a download from Internet Archive.  If the file
  # requires on-the-fly generation, this will be triggered here.
  #
  # If the generation is in progress, the return status will be
  #
  # @param [Hash] opt                 Includes :identifier and :type.
  #
  # @return [Hash]
  #
  # @see file:app/assets/javascripts/feature/download.js *ProbeResponse*
  #
  def probe(**opt)
    api(:get, **opt, json_only: true)
    api_return(IaDownload::Message::ProbeResponse).to_h
  end

  # Get a download from Internet Archive, possibly generated on-the-fly.
  #
  # This should only be invoked after #probe indicates that the requested
  # content file has been generated.
  #
  # @param [Hash] opt                 Includes :identifier and :type.
  #
  # @raise [ExecError]                If the download failed.
  #
  # @return [Array(String,String,String)]
  # @return [Array(String,String,nil)]
  #
  def download(**opt)
    api(:get, **opt)
    resp = api_return(IaDownload::Message::FetchResponse)
    name = resp.filename || opt.slice(:identifier, :type).join('.')
    type = resp.type
    data = resp.content
    return name, type, data
  end

end

__loading_end(__FILE__)
