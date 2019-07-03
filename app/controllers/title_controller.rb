# app/controllers/title_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# TitleController
#
# @see TitleHelper
#
class TitleController < ApplicationController

  include ApiConcern
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern

  include TitleHelper

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
  before_action { @bookshare_id = params[:bookshareId] || params[:id] }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /title
  # List all catalog titles.
  #
  def index
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
    opt  = pagination_setup
    list = @api.get_titles(**opt)
    self.page_items  = list.titles
    self.total_items = list.totalResults
    self.next_page   = next_page_path(list, opt)
  end

  # == GET /title/:id
  # Display details of an existing catalog title.
  #
  def show
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
    @item = @api.get_title(bookshareId: @bookshare_id)
  end

  # == GET /title/new[?id=:id]
  # Add metadata for a new catalog title.
  #
  def new
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == POST /title/:id
  # Create an entry for a new catalog title.
  #
  def create
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == GET /title/:id/edit
  # Modify metadata of an existing catalog title entry.
  #
  def edit
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == PUT   /title/:id
  # == PATCH /title/:id
  # Update the entry for an existing catalog title.
  #
  def update
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == DELETE /title/:id
  # Remove an existing catalog title entry.
  #
  def destroy
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

end

__loading_end(__FILE__)
