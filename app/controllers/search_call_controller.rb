# app/controllers/search_call_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Access search call instances.
#
# @see SearchCallDecorator
# @see SearchCallsDecorator
# @see file:app/views/search_call/**
#
class SearchCallController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include SerializationConcern
  include SearchCallConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    # :nocov:
  end

  # Initially extend table with a column for each JSON sub-field.
  #
  # @type [Boolean]
  #
  # @note Turned off until SqlMethods is updated for Postgres JSON fields.
  #
  EXPAND_JSON = false

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_admin!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /search_call?[expand=TRUE&like=PATTERN&field=MATCH&...]
  #
  # List searches.
  #
  # @see #search_call_index_path      Route helper
  # @see SearchCallConcern#get_search_calls
  # @see SearchCall#extended_table
  #
  def index
    __log_activity
    __debug_route
    prm       = paginator.initial_parameters
    @extended = prm.key?(:expand) ? true?(prm.delete(:expand)) : EXPAND_JSON
    search    = prm.delete(:like) # TODO: :like param
    search    = search ? build_query_options(search) : {}
    results   =
      if @extended
        SearchCall.extended_table(search)
      else
        get_search_calls(search)
      end
    results.limit!(prm[:limit])   if prm[:limit]  # TODO: temporary
    results.offset!(prm[:offset]) if prm[:offset] # TODO: temporary
    @list = results.to_a
    paginator.finalize(@list, **search)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /search_call/:id
  #
  # Display details of a search.
  #
  # @see #search_call_path            Route helper
  # @see SearchCall#find
  #
  def show
    __log_activity
    __debug_route
    @item = SearchCall.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Search::Message::SearchRecordList,nil] list
  # @param [Hash]                                  opt
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
  # @param [SearchCall, Hash] item
  # @param [Hash]             opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def show_values(item = @item, **opt)
    opt.reverse_merge!(name: :search_call)
    if item.is_a?(SearchCall)
      result = item.as_search_parameters
    else
      result = item.to_h.deep_symbolize_keys
    end
    super(result, **opt)
  end

end

__loading_end(__FILE__)
