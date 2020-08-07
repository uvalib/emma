# app/controllers/concerns/ingest_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# IngestConcern
#
module IngestConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'IngestConcern')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA Federated Ingest API service.
  #
  # @return [IngestService]
  #
  def ingest_api
    @ingest_api ||= ingest_api_update
  end

  # Update the EMMA Federated Ingest API service.
  #
  # @param [Hash] opt
  #
  # @return [IngestService]
  #
  def ingest_api_update(**opt)
    opt[:user] = current_user if !opt.key?(:user) && current_user.present?
    opt[:no_raise] = true     if !opt.key?(:no_raise) && Rails.env.test?
    # noinspection RubyYardReturnMatch
    @ingest_api = IngestService.update(**opt)
  end

  # Remove the EMMA Federated Ingest API service.
  #
  # @return [nil]
  #
  def ingest_api_clear
    @ingest_api = IngestService.clear
  end

  # Indicate whether the EMMA Federated Ingest API service has been
  # activated.
  #
  def ingest_api_active?
    defined?(:@ingest_api) && @ingest_api.present?
  end

  # Indicate whether the latest EMMA Federated Ingest API request generated
  # an exception.
  #
  def ingest_api_error?
    ingest_api_active? && @ingest_api&.error?
  end

  # Get the current EMMA Federated Ingest API exception message.
  #
  # @return [String]                  Current service error message.
  # @return [nil]                     No service error or service not active.
  #
  def ingest_api_error_message
    @ingest_api&.error_message if ingest_api_active?
  end

  # Get the current EMMA Federated Ingest API exception.
  #
  # @return [Exception]               Current service exception.
  # @return [nil]                     No exception or service not active.
  #
  def ingest_api_exception
    @ingest_api&.exception if ingest_api_active?
  end

end

__loading_end(__FILE__)
