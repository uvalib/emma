# app/controllers/search_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchController
#
class SearchController < ApplicationController

  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include SearchConcern

  # Non-functional hints for RubyMine.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # before_action :update_user

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action { @title_id = params[:titleId] || params[:id] }

  # URL parameter aliases for :identifier.
  before_action(only: :index) do
    opt = request_parameters
    id_alias = opt.extract!(*PublicationIdentifier::TYPES)
    if id_alias.present?
      search_terms = id_alias.map { |type, term| "#{type}:#{term}" }.join(' ')
      redirect_to opt.merge!(identifier: search_terms)
    end
  end

  # Translate an identifier query to a keyword query if the search term does
  # not look like a valid identifier.
  before_action(only: :index) do
    opt = request_parameters
    identifier = (opt[:identifier] if opt[:q].blank?)
    if identifier.present? && PublicationIdentifier.cast(identifier).blank?
      keyword = identifier.sub(/^[^:]+:/, '')
      redirect_to opt.except(:identifier).merge!(q: keyword)
    end
  end

  # Translate a keyword query for an identifier into an identifier query.
  # For other query types, queries that include a standard identifier prefix
  # (e.g. "isbn:...") are re-cast as :identifier queries.
  before_action(only: :index) do
    opt = request_parameters
    QUERY_PARAMETERS.find do |q_param|
      next if (q_param == :identifier) || (query = opt[q_param]).blank?
      next if (identifier = PublicationIdentifier.cast(query)).blank?
      redirect_to opt.except!(q_param).merge!(identifier: identifier.to_s)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /search
  # Perform a search through the EMMA Unified Search API.
  #
  def index
    __debug_route
    opt      = pagination_setup
    s_params = opt.except(*NON_SEARCH_KEYS)
    q_params, s_params = partition_options(s_params, *QUERY_PARAMETERS)
    q_params.reject! { |_, v| v.blank? }
    if q_params.present?
      opt = opt.slice(*NON_SEARCH_KEYS).merge!(s_params, q_params)
      @list = search_api.get_records(**opt)
      self.page_items  = @list.records
      self.total_items = @list.totalResults
      self.next_page   = next_page_path(@list, opt) # TODO: ???
      respond_to do |format|
        format.html { render layout: layout }
        format.json { render_json index_values }
        format.xml  { render_xml  index_values }
      end
    elsif s_params.present?
      redirect_to opt.merge!(q: NULL_SEARCH)
    else
      render 'search/advanced'
    end
  end

  # == GET /search/:id
  # Display details of an existing catalog title.
  #
  def show
    __debug_route
    @item = search_api.get_record(titleId: @title_id)
    respond_to do |format|
      format.html { render layout: layout }
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /search/advanced
  # Present the advanced search form.
  #
  def advanced
    __debug_route
  end

  # == GET /search/api?...
  # == GET /search/direct?...
  # Perform a search directly through the EMMA Unified Search API.
  #
  def direct
    __debug_route
    opt = pagination_setup.reverse_merge(q: NULL_SEARCH)
    @list = search_api.get_records(**opt)
    self.page_items  = @list.records
    self.total_items = @list.totalResults
    respond_to do |format|
      format.html { render 'search/index', layout: layout }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /search/example
  # Perform an example (fake) search simulating the EMMA Unified Search API.
  #
  def example
    __debug_route
    opt   = pagination_setup
    @list = search_api.get_example_records(**opt)
    self.page_items  = @list.records
    self.total_items = @list.records.size
    render template: 'search/index'
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Search::SearchRecordList] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { records: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Search::Record::MetadataRecord, Hash] item
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item)
    { records: normalize_keys(item) }
  end

end

__loading_end(__FILE__)
