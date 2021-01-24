# app/controllers/edition_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/edition" pages.
#
# @see EditionHelper
#
# == Usage Notes
# The abilities to retrieve or modify editions (instances of remediated
# content) is dependent on the role(s) of the authenticated user.
#
class EditionController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include BsDownloadConcern

  # Non-functional hints for RubyMine type checking.
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

  before_action :set_series_id
  before_action :set_edition_id,  except: %i[index]
  before_action :set_format
  before_action :set_member,      only: %i[download]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /edition?seriesId=:seriesId
  #
  # List all editions for a periodical.
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = bs_api.get_periodical_editions(seriesId: @series_id, **opt)
    self.page_items  = @list.periodicalEditions || []
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /edition/:id?seriesId=:seriesId
  # == GET /edition/:editionId?seriesId=:seriesId
  #
  # Display details of an existing edition.
  #
  def show
    __debug_route
    opt   = { seriesId: @series_id, editionId: @edition_id }
    @item = bs_api.get_periodical_edition(**opt)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /edition/new[?id=:id]
  # == GET /edition/new[?editionId=:editionId]
  #
  # Add metadata for a new edition.
  #
  def new
    __debug_route
  end

  # == POST /edition/:id
  # == POST /edition/:editionId
  #
  # Upload a new edition.
  #
  def create
    __debug_route
  end

  # == GET /edition/:id/edit
  # == GET /edition/:editionId/edit
  #
  # Modify metadata of an existing edition entry.
  #
  def edit
    __debug_route
  end

  # == PUT   /edition/:id
  # == PUT   /edition/:editionId
  # == PATCH /edition/:id
  # == PATCH /edition/:editionId
  #
  # Upload a replacement for an existing edition.
  #
  def update
    __debug_route
  end

  # == DELETE /edition/:id
  # == DELETE /edition/:editionId
  #
  # Remove an existing edition entry.
  #
  def destroy
    __debug_route
  end

  # == GET /edition/:id/:fmt?seriesId=:seriesId&member=BS_ACCOUNT_ID
  # == GET /edition/:editionId/:fmt?seriesId=:seriesId&member=BS_ACCOUNT_ID
  #
  # Download a periodical edition.
  #
  def download
    __debug_route
    opt = {
      seriesId:  @series_id,
      editionId: @edition_id,
      format:    @format,
      forUser:   @member
    }
    bs_download_response(:download_periodical_edition, **opt)
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [ApiPeriodicalEditionList] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list)
    { editions: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Bs::Record::PeriodicalEdition, Hash] item
  #
  # @return [Hash{Symbol=>Bs::Record::PeriodicalEdition,Hash}]
  #
  def show_values(item = @item, **)
    { edition: item }
  end

end

__loading_end(__FILE__)
