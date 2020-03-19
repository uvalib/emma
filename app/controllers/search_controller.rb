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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /search
  # Perform a search through the EMMA Unified Search API.
  #
  def index
    __debug_route
    search_params = url_parameters.except(*NON_SEARCH_KEYS)
    query = search_params.delete(:q).presence
    query = false if search_params.blank? && (query == NULL_SEARCH)
    opt   = pagination_setup
    if query
      @list = api.get_records(**opt)
      self.page_items  = @list.records
      self.total_items = @list.totalResults
      self.next_page   = next_page_path(@list, opt) # TODO: ???
      respond_to do |format|
        format.html
        format.json { render_json index_values }
        format.xml  { render_xml  index_values }
      end
    elsif search_params.present?
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
    @item = api.get_record(titleId: @title_id)
    respond_to do |format|
      format.html
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
    @list = api.get_records(**opt)
    self.page_items  = @list.records
    self.total_items = @list.totalResults
    respond_to do |format|
      format.html { render 'search/index' }
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
    @list = api.get_example_records(**opt)
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
