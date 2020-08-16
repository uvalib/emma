# app/controllers/concerns/ia_download_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# IaDownloadConcern
#
module IaDownloadConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'IaDownloadConcern')

    include RepositoryHelper

  end

  include ActionController::DataStreaming
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
    @ia_download_api ||= ia_download_api_update
  end

  # ia_download_api_update
  #
  # @param [Hash] opt
  #
  # @return [IaDownloadService]
  #
  def ia_download_api_update(**opt)
    opt[:user] = current_user if !opt.key?(:user) && current_user.present?
    opt[:no_raise] = true     if !opt.key?(:no_raise) && Rails.env.test?
    # noinspection RubyYardReturnMatch
    @ia_download_api = IaDownloadService.update(**opt)
  end

  # ia_download_api_clear
  #
  # @return [nil]
  #
  def ia_download_api_clear
    @ia_download_api = IaDownloadService.clear
  end

  # ia_download_api_active?
  #
  def ia_download_api_active?
    defined?(:@ia_download_api) && @ia_download_api.present?
  end

  # ia_download_api_error?
  #
  def ia_download_api_error?
    ia_download_api_active? && @ia_download_api&.error?
  end

  # ia_download_api_error_message
  #
  # @return [String]                  Current service error message.
  # @return [nil]                     No service error or service not active.
  #
  def ia_download_api_error_message
    @ia_download_api&.error_message if ia_download_api_active?
  end

  # ia_download_api_exception
  #
  # @return [Exception]               Current service exception.
  # @return [nil]                     No exception or service not active.
  #
  def ia_download_api_exception
    @ia_download_api&.exception if ia_download_api_active?
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
  def render_ia_download(url, **opt)
    name, type, data = ia_download_api.download(url, **opt)
    send_data(data, type: type, filename: name) if data.present?
  end

end

__loading_end(__FILE__)
