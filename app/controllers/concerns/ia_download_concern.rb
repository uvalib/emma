# app/controllers/concerns/ia_download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for downloads from Internet Archive.
#
module IaDownloadConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'IaDownloadConcern')

    include RepositoryHelper

  end

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
  # @return [void]
  #
  def ia_download_response(url, **opt)
    name, type, data = ia_download_api.download(url, **opt)
    send_data(data, type: type, filename: name) if data.present?
  end

end

__loading_end(__FILE__)
