# app/controllers/periodical_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/periodical" pages.
#
# @see PeriodicalHelper
# @see file:app/views/periodical/**
#
# @note These endpoints are not currently presented as a part of EMMA.
#
class PeriodicalController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include SerializationConcern
  include BookshareConcern

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
  before_action :authenticate_user!, except: %i[index show]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_series_id

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /periodical
  #
  # List all periodicals.
  #
  # @see BookshareService::Request::Periodicals#get_periodicals
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = bs_api.get_periodicals(**opt)
    pagination_finalize(@list, :periodicals, **opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /periodical/:id
  #
  # Display details of an existing periodical.
  #
  # @see BookshareService::Request::Periodicals#get_periodical
  # @see BookshareService::Request::Periodicals#get_periodical_editions
  #
  def show
    __debug_route
    opt   = pagination_setup
    @item = bs_api.get_periodical(seriesId: @series_id)
    @list = bs_api.get_periodical_editions(seriesId: @series_id)
    pagination_finalize(@list, :periodicalEditions, **opt)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values(nil, as: :array) }
    end
  end

  # == GET /periodical/new[?id=:id]
  #
  # Add metadata for a new periodical.
  #
  def new
    __debug_route
  end

  # == POST /periodical/:id
  #
  # Create an entry for a new periodical.
  #
  def create
    __debug_route
  end

  # == GET /periodical/:id/edit
  #
  # Modify metadata of an existing periodical entry.
  #
  def edit
    __debug_route
  end

  # == PUT   /periodical/:id
  # == PATCH /periodical/:id
  #
  # Update the entry for an existing periodical.
  #
  def update
    __debug_route
  end

  # == DELETE /periodical/:id
  #
  # Remove an existing periodical entry.
  #
  def destroy
    __debug_route
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Bs::Message::PeriodicalSeriesMetadataSummaryList] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list)
    { periodicals: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Hash, nil]   result
  # @param [Symbol, nil] as           Either :hash or :array if given.
  #
  # @return [Hash{Symbol=>Hash,Array}]
  #
  def show_values(result = nil, as: nil)
    result ||= { details: @item, editions: @list }
    { periodical: super(result, as: as) }
  end

end

__loading_end(__FILE__)
