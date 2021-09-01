# app/controllers/concerns/ia_download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for downloads from Internet Archive.
#
module IaDownloadConcern

  extend ActiveSupport::Concern

  include ActionController::DataStreaming

  include ApiConcern

  include SerializationHelper

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

  # Send a copy of a file downloaded from Internet Archive.
  #
  # @param [String] url
  # @param [Hash]   opt               Request headers,
  #
  # @raise [ExecError] @see IaDownloadService#download
  #
  # @return [void]
  #
  def ia_download_response(url, **opt)
    name, type, data = ia_download_api.download(url, **opt)
    send_data(data, type: type, filename: name) if data.present?
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
