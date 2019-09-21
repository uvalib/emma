# app/controllers/edition_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EditionController
#
# @see EditionHelper
#
# == Usage Notes
# The abilities to retrieve or modify editions (instances of remediated
# content) is dependent on the role(s) of the authenticated user.
#
class EditionController < ApplicationController

  include ApiConcern
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include DownloadConcern

  include EditionHelper

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

  before_action { @edition_id = params[:editionId] || params[:id] }
  before_action { @series_id  = params[:seriesId] }
  before_action { @format     = params[:fmt] || Api::FormatType.new.default }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /edition?seriesId=:seriesId
  # List all editions for a periodical.
  #
  def index
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
    opt   = pagination_setup
    @list = api.get_periodical_editions(seriesId: @series_id, **opt)
    self.page_items  = @list.periodicalEditions
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
  # Display details of an existing edition.
  #
  def show
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
    opt   = { seriesId: @series_id, editionId: @edition_id }
    @item = api.get_periodical_edition(**opt)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /edition/new[?id=:id]
  # == GET /edition/new[?editionId=:editionId]
  # Add metadata for a new edition.
  #
  def new
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == POST /edition/:id
  # == POST /edition/:editionId
  # Upload a new edition.
  #
  def create
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == GET /edition/:id/edit
  # == GET /edition/:editionId/edit
  # Modify metadata of an existing edition entry.
  #
  def edit
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == PUT   /edition/:id
  # == PUT   /edition/:editionId
  # == PATCH /edition/:id
  # == PATCH /edition/:editionId
  # Upload a replacement for an existing edition.
  #
  def update
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == DELETE /edition/:id
  # == DELETE /edition/:editionId
  # Remove an existing edition entry.
  #
  def destroy
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
  end

  # == GET /edition/:id/:fmt?seriesId=:seriesId
  # == GET /edition/:editionId/:fmt?seriesId=:seriesId
  # Download a periodical edition.
  #
  def download
    __debug { "EDITION #{__method__} | params = #{params.inspect}" }
    opt = { seriesId: @series_id, editionId: @edition_id, format: @format }
    render_download api.download_periodical_edition(**opt)
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [ApiPeriodicalEditionList, nil] list
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { editions: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Api::PeriodicalEdition, nil] item
  # @param [Symbol]                      as     Unused.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item, as: nil)
    { edition: item }
  end

end

__loading_end(__FILE__)
