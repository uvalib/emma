# app/controllers/concerns/search_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/search" controller.
#
module SearchConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'SearchConcern')
  end

  include ApiConcern
  include SearchHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether search calls should be recorded by default.
  #
  # @type [Boolean]
  #
  SAVE_SEARCHES = true?(ENV.fetch('SAVE_SEARCHES', true))

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the EMMA Unified Search API service.
  #
  # @return [SearchService]
  #
  def search_api
    # noinspection RubyYardReturnMatch
    api_service(SearchService)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the current search should be recorded.
  #
  # @param [User, nil] user           Default: `#current_user`.
  #
  def save_search?(user = nil)
    SAVE_SEARCHES # TODO: criteria?
  end

  # Record a search call.
  #
  # @param [User, nil]    user        Default: `#current_user`.
  # @param [Array, #to_a] result      Default: @list.
  # @param [Boolean]      force       Save even if #save_search? is *false*.
  # @param [Hash]         parameters  Default: `#url_parameters`.
  #
  # @return [SearchCall]              New record.
  # @return [nil]                     If saving was not possible.
  #
  def save_search(user: nil, result: nil, force: false, **parameters)
    user ||= current_user
    return unless force || save_search?(user)
    attr = url_parameters(parameters)
    attr[:controller] ||= :search
    attr[:action]     ||= :index
    attr[:user]       ||= user
    attr[:result]     ||= result || @list
    # noinspection RubyYardReturnMatch
    SearchCall.create(attr)
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
  def sanitize_keys(value)
    if value.is_a?(Hash)
      value
        .transform_keys   { |k| k.to_s.downcase.tr('^a-z0-9_', '_') }
        .transform_values { |v| sanitize_keys(v) }
    elsif value.is_a?(Array) && (value.size > 1)
      value.map { |v| sanitize_keys(v) }
    elsif value.is_a?(Array)
      sanitize_keys(value.first)
    elsif value.is_a?(String) && value.include?(FileFormat::FILE_FORMAT_SEP)
      value.split(FileFormat::FILE_FORMAT_SEP).reject(&:blank?)
    else
      value
    end
  end

  # Indicate whether search menu selections should take immediate effect.
  #
  # @param [*] value
  #
  # @return [Symbol]                  New setting value.
  # @return [nil]                     If the setting was not changed.
  #
  # @see LayoutHelper#immediate_search?
  #
  def set_immediate_search(value)
    # TODO: accept only for authenticated user
    if %i[true false].include?(value)
      @immediate_search = value
    elsif true?(value)
      @immediate_search = :true
    elsif false?(value)
      @immediate_search = :false
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
    search_query_keys(**opt).find do |q_param|
      next if (q_param == :identifier) || (query = opt[q_param]).blank?
      next if (identifier = PublicationIdentifier.cast(query)).blank?
      opt[:identifier] = identifier.to_s
      redirect_to opt.except!(q_param)
    end
  end

end

__loading_end(__FILE__)
