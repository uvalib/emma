# app/controllers/periodical_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# PeriodicalController
#
# @see PeriodicalHelper
#
class PeriodicalController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include BookshareConcern

  # Non-functional hints for RubyMine.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

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

  before_action { @series_id = params[:seriesId] || params[:id] }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /periodical
  # List all periodicals.
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = bs_api.get_periodicals(**opt)
    self.page_items  = @list.periodicals
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html { render layout: layout }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /periodical/:id
  # Display details of an existing periodical.
  #
  def show
    __debug_route
    @item = bs_api.get_periodical(seriesId: @series_id)
    @list = bs_api.get_periodical_editions(seriesId: @series_id, no_raise: true)
    self.page_items  = @list.periodicalEditions
    self.total_items = @list.totalResults
    respond_to do |format|
      format.html { render layout: layout }
      format.json { render_json show_values(as: :hash)  }
      format.xml  { render_xml  show_values(as: :array) }
    end
  end

  # == GET /periodical/new[?id=:id]
  # Add metadata for a new periodical.
  #
  def new
    __debug_route
  end

  # == POST /periodical/:id
  # Create an entry for a new periodical.
  #
  def create
    __debug_route
  end

  # == GET /periodical/:id/edit
  # Modify metadata of an existing periodical entry.
  #
  def edit
    __debug_route
  end

  # == PUT   /periodical/:id
  # == PATCH /periodical/:id
  # Update the entry for an existing periodical.
  #
  def update
    __debug_route
  end

  # == DELETE /periodical/:id
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
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { periodicals: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @overload show_values(as: :array)
  #   @return [Hash{Symbol=>Array}]
  #
  # @overload show_values(as: :hash)
  #   @return [Hash{Symbol=>Hash}]
  #
  # @overload show_values
  #   @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  # noinspection RubyYardReturnMatch
  def show_values(as: nil)
    result = { details: @item, editions: @list }
    { periodical: super(result, as: as) }
  end

end

__loading_end(__FILE__)
