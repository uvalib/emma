# app/services/ia_download_service/action/records.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IaDownloadService::Action::Records
#
#--
# noinspection RubyParameterNamingConvention
#++
module IaDownloadService::Action::Records

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
  # @return [Array<(String,String,String)>]
  # @return [Array<(String,String,nil)>]
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
