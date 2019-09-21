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

  include ApiConcern
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern

  include PeriodicalHelper

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :authenticate_user!, except: %i[index show]
  before_action :update_user

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
    __debug { "PERIODICAL #{__method__} | params = #{params.inspect}" }
    opt   = pagination_setup
    @list = api.get_periodicals(**opt)
    self.page_items  = @list.periodicals
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /periodical/:id
  # Display details of an existing periodical.
  #
  def show
    __debug { "PERIODICAL #{__method__} | params = #{params.inspect}" }
    @item = api.get_periodical(seriesId: @series_id)
    @list = api.get_periodical_editions(seriesId: @series_id)
    self.page_items  = @list.periodicalEditions
    self.total_items = @list.totalResults
    respond_to do |format|
      format.html
      format.json { render_json show_values(as: :hash)  }
      format.xml  { render_xml  show_values(as: :array) }
    end
  end

  # == GET /periodical/new[?id=:id]
  # Add metadata for a new periodical.
  #
  def new
    __debug { "PERIODICAL #{__method__} | params = #{params.inspect}" }
  end

  # == POST /periodical/:id
  # Create an entry for a new periodical.
  #
  def create
    __debug { "PERIODICAL #{__method__} | params = #{params.inspect}" }
  end

  # == GET /periodical/:id/edit
  # Modify metadata of an existing periodical entry.
  #
  def edit
    __debug { "PERIODICAL #{__method__} | params = #{params.inspect}" }
  end

  # == PUT   /periodical/:id
  # == PATCH /periodical/:id
  # Update the entry for an existing periodical.
  #
  def update
    __debug { "PERIODICAL #{__method__} | params = #{params.inspect}" }
  end

  # == DELETE /periodical/:id
  # Remove an existing periodical entry.
  #
  def destroy
    __debug { "PERIODICAL #{__method__} | params = #{params.inspect}" }
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [ApiPeriodicalSeriesMetadataSummaryList, nil] list
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { periodicals: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [ApiPeriodicalSeriesMetadataSummary, nil] item
  # @param [ApiPeriodicalEditionList, nil]           list
  # @param [Symbol]                                  as
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item, list = @list, as: nil)
    { periodical: super(details: item, editions: list, as: as) }
  end

end

__loading_end(__FILE__)
