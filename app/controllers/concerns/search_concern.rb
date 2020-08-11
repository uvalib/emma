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
  # @return [String]                  Current service error message.
  # @return [nil]                     No service error or service not active.
  #
  def search_api_error_message
    @search_api&.error_message if search_api_active?
  end

  # Get the current EMMA Unified Search API exception.
  #
  # @return [Exception]               Current service exception.
  # @return [nil]                     No exception or service not active.
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
      value.split(FileFormat::FILE_FORMAT_SEP).reject(&:blank?)
    else
      value
    end
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Extract the URL parameter which specifies a title.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :titleId found.
  #
  def set_title_id
    # noinspection RubyYardReturnMatch
    @title_id = params[:titleId] || params[:id]
  end

  # Re-cast URL parameters which are aliases for :identifier and redirect to
  # the modified URL if found.
  #
  # @return [void]
  #
  def identifier_alias_redirect
    opt     = request_parameters
    aliases = opt.extract!(*PublicationIdentifier::TYPES)
    return if aliases.blank?
    opt[:identifier] = aliases.map { |type, term| "#{type}:#{term}" }.join(' ')
    redirect_to opt
  end

  # Translate an identifier query to a keyword query if the search term does
  # not look like a valid identifier.
  #
  # @return [void]
  #
  def invalid_identifier_redirect
    opt = request_parameters
    return if opt[:q].present?
    return if (identifier = opt[:identifier]).blank?
    return if PublicationIdentifier.cast(identifier).present?
    opt[:q] = identifier.sub(/^[^:]+:/, '')
    redirect_to opt.except!(:identifier)
  end

  # Translate a keyword query for an identifier into an identifier query.
  # For other query types, queries that include a standard identifier prefix
  # (e.g. "isbn:...") are re-cast as :identifier queries.
  #
  # @return [void]
  #
  def identifier_keyword_redirect
    opt = request_parameters
    QUERY_PARAMETERS.find do |q_param|
      next if (q_param == :identifier) || (query = opt[q_param]).blank?
      next if (identifier = PublicationIdentifier.cast(query)).blank?
      opt[:identifier] = identifier.to_s
      redirect_to opt.except!(q_param)
    end
  end

end

__loading_end(__FILE__)
