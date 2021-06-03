# app/controllers/search_call_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Access search call instances.
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
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # Initially extend table with a column for each JSON sub-field.
  #
  # @type [Boolean]
  #
  EXPAND_JSON = true

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!

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
  def index
    __debug_route
    prm       = request_parameters
    @extended = prm.key?(:expand) ? true?(prm.delete(:expand)) : EXPAND_JSON
    search    = prm.delete(:like) # TODO: :like param
    search  &&= build_query_options(search)
    search  ||= search_call_params(prm) # TODO: remove - testing
    @list =
      if @extended
        SearchCall.extended_table(search)
      else
        get_search_calls(search)
      end
    @list = @list.to_a
    pagination_finalize(@list, **search)
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
  def show
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
  # @param [Search::SearchRecordList] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list)
    { records: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [SearchCall, Hash] item
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def show_values(item = @item, **)
    if item.is_a?(SearchCall)
      value = item.as_search_parameters
    else
      value = item.to_h.deep_symbolize_keys
    end
    { search_call: value }
  end

end

__loading_end(__FILE__)
