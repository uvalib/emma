# app/services/ia_download_service/request/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IaDownloadService::Request::Records
#
#--
# noinspection RubyParameterNamingConvention
#++
module IaDownloadService::Request::Records

  include IaDownloadService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get a download from Internet Archive, possibly generated on-the-fly.
  #
  # @param [String] url
  # @param [Hash]   opt
  #
  # @raise [ExecError]                If the download failed.
  #
  # @return [(String,String,String)]
  # @return [(String,String,nil)]
  #
  def download(url, **opt)
    api(:get, url, **opt)
    data = response.body
    type = response['Content-Type']
    disp = response['Content-Disposition']
    name = disp.to_s.sub(/^.*filename=([^;]+)(;.*)?$/, '\1').presence
    type ||= 'application/octet-stream'
    name ||= File.basename(url)
    return name, type, data
  end

end

__loading_end(__FILE__)
