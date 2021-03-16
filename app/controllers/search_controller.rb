# app/controllers/search_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/search" requests.
#
class SearchController < ApplicationController

  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include SearchConcern

  # Non-functional hints for RubyMine type checking.
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

  before_action :identifier_alias_redirect,   only: %i[index]
  before_action :invalid_identifier_redirect, only: %i[index]
  before_action :identifier_keyword_redirect, only: %i[index]
  before_action :set_title_id,                only: %i[show]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /search
  #
  # Perform a search through the EMMA Unified Search API.
  #
  def index
    __debug_route
    opt      = pagination_setup
    search   = opt.delete(:search_call) || opt
    s_params = search.except(*NON_SEARCH_KEYS)
    q_params, s_params = partition_options(s_params, *search_query_keys)
    q_params.reject! { |_, v| v.blank? }
    if q_params.present?
      opt = opt.slice(*NON_SEARCH_KEYS).merge!(s_params, q_params)
      set_immediate_search(opt.delete(:immediate_search))
      @list = search_api.get_records(**opt)
      save_search(**opt)
      self.page_items  = @list.records
      self.total_items = @list.totalResults
      self.next_page   = next_page_path(**opt)
      respond_to do |format|
        format.html
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
  #
  # Display details of an existing catalog title.
  #
  def show
    __debug_route
    @item = search_api.get_record(titleId: @title_id)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /search/advanced
  #
  # Present the advanced search form.
  #
  def advanced
    __debug_route
  end

  # == GET /search/api?...
  # == GET /search/direct?...
  #
  # Perform a search directly through the EMMA Unified Search API.
  #
  def direct
    __debug_route
    opt = pagination_setup.reverse_merge(q: NULL_SEARCH)
    @list = search_api.get_records(**opt)
    self.page_items  = @list.records
    self.total_items = @list.totalResults
    respond_to do |format|
      format.html { render 'search/index' }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
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
  def index_values(list = @list)
    { records: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Search::Record::MetadataRecord, Hash] item
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def show_values(item = @item, **)
    sanitize_keys(item)
  end

end

__loading_end(__FILE__)
