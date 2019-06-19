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

  before_action :initialize_service
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
    opt  = pagination_setup
    list = @api.get_periodicals(**opt)
    page_items(list.periodicals)
    total_items(list.totalResults)
    next_page(next_page_path(list, opt))
  end

  # == GET /periodical/:id
  # Display details of an existing periodical.
  #
  def show
    __debug { "PERIODICAL #{__method__} | params = #{params.inspect}" }
    @item = @api.get_periodical(seriesId: @series_id)
    list  = @api.get_periodical_editions(seriesId: @series_id)
    page_items(list.periodicalEditions)
    total_items(list.totalResults)
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

end

__loading_end(__FILE__)
