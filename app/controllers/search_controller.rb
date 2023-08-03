# app/controllers/search_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/search" requests.
#
# @see SearchDecorator
# @see SearchesDecorator
# @see file:app/views/search/**
#
class SearchController < ApplicationController

  include UserConcern
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

  before_action :update_user

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
  before_action :set_immediate_search,        only: %i[index]
  before_action :set_search_engine,           only: %i[index]
  before_action :set_search_results,          only: %i[index]
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

  # === GET /search
  #
  # Perform a search through the EMMA Unified Search API.
  #
  # @see #search_index_path           Route helper
  # @see SearchConcern#index_search
  #
  def index
    __log_activity(anonymous: true)
    __debug_route
    err   = nil
    prm      = paginator.initial_parameters
    playback = prm.delete(:search_call)
    s_params = (playback || prm).except(*Paginator::NON_SEARCH_KEYS)
    q_params = s_params.extract!(*search_query_keys).compact_blank!
    if q_params.blank?
      if s_params.present?
        redirect_to prm.merge!(q: SearchTerm::NULL_SEARCH)
      else
        render 'search/advanced'
      end
      return
    end
    prm    = prm.slice(*Paginator::NON_SEARCH_KEYS).merge!(s_params, q_params)
    titles = title_results?
    @list  = index_search(titles: titles, save: !playback, **prm)
    err    = @list.exec_report if @list.error?
    paginator.finalize(@list, (titles ? :titles : :records), **prm)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :record)  }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # === GET /search/:id
  #
  # Display details of an existing catalog title.
  #
  # @see #search_path                 Route helper
  # @see SearchConcern#index_record
  #
  # @note This endpoint is not actually functional because it depends on an
  #   EMMA Unified Search API endpoint which does not exist.
  #
  def show
    __log_activity(anonymous: true)
    __debug_route
    err   = nil
    @item = index_record(record_id: @record_id)
    err   = @item.exec_report if @item.error?
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /search/advanced
  #
  # Present the advanced search form.
  #
  # @see #advanced_search_path        Route helper
  #
  def advanced
    __log_activity(anonymous: true)
    __debug_route
  end

  # === GET /search/api?...
  # === GET /search/direct?...
  #
  # Perform a search directly through the EMMA Unified Search API.
  #
  # Although this is primarily for the sake of JSON output, it also provides an
  # HTML display where results have a one-to-one correspondence with EMMA
  # Unified Search results as an alternative to the hierarchical display that
  # is the default for :index.
  #
  # @see #search_api_path             Route helper
  # @see #search_direct_path          Route helper
  # @see SearchConcern#index_search
  #
  def direct
    __log_activity(anonymous: true)
    __debug_route
    force_file_results
    prm     = paginator.initial_parameters
    prm[:q] = SearchTerm::NULL_SEARCH if prm.slice(*search_query_keys).blank?
    @list   = index_search(titles: false, save: false, scores: false, **prm)
    paginator.finalize(@list, :records, **prm)
    flash_now_alert(@list.exec_report) if @list.error?
    respond_to do |format|
      format.html { render 'search/index' }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  rescue => error
    flash_now_failure(error)
    render 'search/index'
  ensure
    reset_results_type
  end

  # === GET /search/validate?identifier=idval1[,idval2[,...]]
  #
  # Indicate whether the supplied value is a valid field value.
  #
  # @see #search_validate_path                  Route helper
  # @see file:javascripts/feature/model-form.js *remoteValidate()*
  # @see file:javascripts/feature/model-form.js *ID_VALIDATE_URL_BASE*
  #
  def validate
    __debug_route
    ids = params[:identifier].presence
    render json: validate_identifiers(ids) if ids
  end

  # === GET /search/image?url=...
  #
  # Get a thumbnail or cover image.
  #
  # @see file:app/assets/javascripts/feature/images.js *urlProxyPath*
  #
  # === Usage Notes
  # This provides JavaScript with a way of asynchronously getting non-local
  # images without having to contend with CSRF.
  #
  def image
    #__log_activity
    # __debug_route
    response   = Faraday.get(params[:url]) # TODO: caching
    image_data = Base64.encode64(response.body)
    mime_type  = response.headers['content-type']
    render plain: image_data, format: mime_type, layout: false
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
    sanitize_keys(super)
  end

end

__loading_end(__FILE__)
