# app/controllers/concerns/search_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchConcern
#
module SearchConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'SearchConcern')
  end

  include SearchHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA Unified Search API service.
  #
  # @return [SearchService]
  #
  def search_api
    @search_api ||= search_api_update
  end

  # Update the EMMA Unified Search API service.
  #
  # @param [Hash] opt
  #
  # @return [SearchService]
  #
  def search_api_update(**opt)
    opt[:user] = current_user if !opt.key?(:user) && current_user.present?
    opt[:no_raise] = true     if !opt.key?(:no_raise) && Rails.env.test?
    # noinspection RubyYardReturnMatch
    @search_api = SearchService.update(**opt)
  end

  # Remove the EMMA Unified Search API service.
  #
  # @return [nil]
  #
  def search_api_clear
    @search_api = SearchService.clear
  end

  # Indicate whether the EMMA Unified Search API service has been activated.
  #
  def search_api_active?
    defined?(:@search_api) && @search_api.present?
  end

  # Indicate whether the latest EMMA Unified Search API request generated an
  # exception.
  #
  def search_api_error?
    search_api_active? && @search_api&.error?
  end

  # Get the current EMMA Unified Search API exception message.
  #
  # @return [String]
  # @return [nil]
  #
  def search_api_error_message
    @search_api&.error_message if search_api_active?
  end

  # Get the current EMMA Unified Search API exception.
  #
  # @return [Exception]
  # @return [nil]
  #
  def search_api_exception
    @search_api&.exception if search_api_active?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Eliminate values from keys that would be problematic when rendering the
  # hash as JSON or XML.
  #
  # @param [*] value
  #
  # @return [*]                       Same type as *value*.
  #
  def normalize_keys(value)
    if value.is_a?(Hash)
      value
        .transform_keys   { |k| k.to_s.downcase.tr('^a-z0-9_', '_') }
        .transform_values { |v| normalize_keys(v) }
    elsif value.is_a?(Array) && (value.size > 1)
      value.map { |v| normalize_keys(v) }
    elsif value.is_a?(Array)
      normalize_keys(value.first)
    elsif value.is_a?(String) && value.include?(FileFormat::FILE_FORMAT_SEP)
      # noinspection RubyYardReturnMatch
      value.split(FileFormat::FILE_FORMAT_SEP).reject(&:blank?)
    else
      value
    end
  end

end

__loading_end(__FILE__)
