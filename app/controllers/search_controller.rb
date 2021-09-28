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

  before_action :identifier_alias_redirect,   only: %i[index]
  before_action :invalid_identifier_redirect, only: %i[index]
  before_action :identifier_keyword_redirect, only: %i[index]
  before_action :set_immediate_search,        only: %i[index]
  before_action :set_search_style,            only: %i[index]
  before_action :set_record_id,               only: %i[show]

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # API results for :index.
  #
  # @return [Search::Message::SearchRecordList]
  #
  attr_reader :list

  # API results for :show.
  #
  # @return [Search::Message::SearchRecord]
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
  # @see SearchService::Request::Records#get_records
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
      opt    = opt.slice(*NON_SEARCH_KEYS).merge!(s_params, q_params)
      result = search_api.get_records(**opt)
      result.calculate_scores!(**opt) unless default_style?
      @list = result
      @list = Search::Message::SearchTitleList.new(result) if aggregate_style?
      pagination_finalize(@list, :records, **opt)
      save_search(**opt)                  unless playback
      flash_now_alert(result.exec_report) if result.error?
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
  # @see SearchService::Request::Records#get_record
  #
  # @note This endpoint is not actually functional because it depends on a
  #   Unified Search API endpoint which does not exist.
  #
  def show
    __debug_route
    @item = search_api.get_record(record_id: @record_id)
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
  # @see SearchService::Request::Records#get_records
  #
  def direct
    __debug_route
    opt   = pagination_setup.reverse_merge(q: NULL_SEARCH)
    @list = search_api.get_records(**opt)
    pagination_finalize(@list, :records, **opt)
    flash_now_alert(@list.exec_report) if @list.error?
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
    # noinspection RubyMismatchedReturnType
    sanitize_keys(item)
  end

end

__loading_end(__FILE__)
