# app/controllers/search_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/search" requests.
#
# @see SearchHelper
# @see file:app/views/search/**
#
class SearchController < ApplicationController

  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include SerializationConcern
  include SearchConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    # :nocov:
  end

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

  before_action(only: %i[v2 v3]) { @search_style = params[:action].to_sym }

  before_action :identifier_alias_redirect,   only: %i[index v2 v3]
  before_action :invalid_identifier_redirect, only: %i[index v2 v3]
  before_action :identifier_keyword_redirect, only: %i[index v2 v3]
  before_action :set_immediate_search,        only: %i[index v2 v3]
  before_action :set_search_engine,           only: %i[index v2 v3]
  before_action :set_search_style,            only: %i[index]
  before_action :set_record_id,               only: %i[show]

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # API results for :index.
  #
  # @return [Search::Message::SearchRecordList]
  # @return [Search::Message::SearchTitleList]
  #
  attr_reader :list

  # API results for :show.
  #
  # @return [Search::Message::SearchRecord, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /search
  #
  # Perform a search through the EMMA Unified Search API.
  #
  # @see SearchConcern#index_search
  #
  def index
    __debug_route
    opt      = pagination_setup
    playback = opt.delete(:search_call)
    search   = playback || opt
    s_params = search.except(*NON_SEARCH_KEYS)
    q_params, s_params = partition_hash(s_params, *search_query_keys)
    q_params.compact_blank!
    if q_params.present?
      opt = opt.slice(*NON_SEARCH_KEYS).merge!(s_params, q_params)
      opt[:save]   = !playback
      opt[:scores] = !default_style?
      opt[:titles] = aggregate_style?
      opt[:items]  = :records
      @list = index_search(**opt)
      respond_to do |format|
        format.html
        format.json { render_json index_values }
        format.xml  { render_xml  index_values(item: :record)  }
      end
    elsif s_params.present?
      redirect_to opt.merge!(q: SearchTerm::NULL_SEARCH)
    else
      render 'search/advanced'
    end
  end

  # == GET /search/v2
  #
  # Perform a search through the EMMA Unified Search API.
  #
  # @see SearchConcern#index_search
  #
  def v2
    __debug_route
    opt      = pagination_setup
    playback = opt.delete(:search_call)
    search   = playback || opt
    s_params = search.except(*NON_SEARCH_KEYS)
    q_params, s_params = partition_hash(s_params, *search_query_keys)
    q_params.compact_blank!
    if q_params.present?
      opt = opt.slice(*NON_SEARCH_KEYS).merge!(s_params, q_params)
      @list = index_search(save: !playback, items: :records, **opt)
      respond_to do |format|
        format.html { render 'search/index' }
        format.json { render_json index_values(@list.records) }
        format.xml  { render_xml  index_values(@list.records, item: :record) }
      end
    elsif s_params.present?
      redirect_to opt.merge!(q: SearchTerm::NULL_SEARCH)
    else
      render 'search/advanced'
    end
  rescue => error
    flash_now_failure(error)
    render 'search/index'
  end

  # == GET /search/v3
  #
  # Perform a search through the EMMA Unified Search API.
  #
  # @see SearchConcern#index_search
  #
  def v3
    __debug_route
    opt      = pagination_setup
    playback = opt.delete(:search_call)
    search   = playback || opt
    s_params = search.except(*NON_SEARCH_KEYS)
    q_params, s_params = partition_hash(s_params, *search_query_keys)
    q_params.compact_blank!
    if q_params.present?
      opt   = opt.slice(*NON_SEARCH_KEYS).merge!(s_params, q_params)
      @list = index_search(save: !playback, **opt)
      respond_to do |format|
        format.html { render 'search/index' }
        format.json { render_json index_values }
        format.xml  { render_xml  index_values(item: :title) }
      end
    elsif s_params.present?
      redirect_to opt.merge!(q: SearchTerm::NULL_SEARCH)
    else
      render 'search/advanced'
    end
  rescue => error
    flash_now_failure(error)
    render 'search/index'
  end

  # == GET /search/:id
  #
  # Display details of an existing catalog title.
  #
  # @see SearchConcern#index_record
  #
  # @note This endpoint is not actually functional because it depends on a
  #   Unified Search API endpoint which does not exist.
  #
  def show
    __debug_route
    @item = index_record(record_id: @record_id)
    flash_now_alert(@item.exec_report) if @item.error?
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # @see SearchConcern#index_search
  #
  def direct
    __debug_route
    opt     = pagination_setup
    opt[:q] = SearchTerm::NULL_SEARCH if opt.slice(*search_query_keys).blank?
    @list   = index_search(titles: false, save: false, scores: false, **opt)
    flash_now_alert(@list.exec_report) if @list.error?
    respond_to do |format|
      format.html { render 'search/index' }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  rescue => error
    flash_now_failure(error)
    render 'search/index'
  end

  # == GET /search/validate?identifier=idval1[,idval2[,...]]
  #
  # Indicate whether the supplied value is a valid field value.
  #
  # @see file:app/assets/javascripts/feature/entry-form.js *remoteValidate()*
  # @see file:app/assets/javascripts/feature/entry-form.js *ID_VALIDATE_URL_BASE*
  #
  def validate
    __debug_route
    opt = request_parameters
    if (ids = opt[:identifier])
      render json: validate_identifiers(ids)
    end
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Search::Message::SearchRecordList, Search::Message::SearchTitleList] list
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :response)
    opt.reverse_merge!(name: list.respond_to?(:titles) ? :titles : :records)
    super(list, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Search::Message::SearchRecord, Hash] item
  # @param [Hash]                                opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def show_values(item = @item, **opt)
    # noinspection RubyMismatchedReturnType
    sanitize_keys(super(item, **opt))
  end

end

__loading_end(__FILE__)
