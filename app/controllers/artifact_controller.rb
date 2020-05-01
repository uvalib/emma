# app/controllers/artifact_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ArtifactController
#
# @see ArtifactHelper
#
# == Usage Notes
# The abilities to retrieve or modify artifacts (instances of remediated
# content) is dependent on the role(s) of the authenticated user.
#
class ArtifactController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include DownloadConcern

  # Non-functional hints for RubyMine.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

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
  # :section: Callbacks
  # ===========================================================================

  before_action { @bookshare_id = params[:bookshareId] || params[:id] }
  before_action { @format = params[:fmt] || FormatType.default }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # TODO: all artifacts? Probably not...
  # == GET /artifact
  # List all artifacts.
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = api.get_artifact_list(**opt)
    self.page_items  = @list.artifacts
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html { render layout: layout }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end
=end

  # == GET /artifact/:id?fmt=:fmt
  # == GET /artifact/:bookshareId?fmt=:fmt
  # Get metadata for an existing artifact.
  #
  def show
    __debug_route
    opt   = { bookshareId: @bookshare_id, format: @format }
    @item = api.get_artifact_metadata(**opt)
    respond_to do |format|
      format.html { render layout: layout }
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /artifact/new[?id=:id]
  # == GET /artifact/new[?bookshareId=:bookshareId]
  # Add metadata for a new artifact.
  #
  def new
    __debug_route
  end

  # == POST /artifact/:id
  # == POST /artifact/:bookshareId
  # Upload a new artifact.
  #
  def create
    __debug_route
  end

  # == GET /artifact/:id/edit
  # == GET /artifact/:bookshareId/edit
  # Modify metadata of an existing artifact entry.
  #
  def edit
    __debug_route
  end

  # == PUT   /artifact/:id
  # == PUT   /artifact/:bookshareId
  # == PATCH /artifact/:id
  # == PATCH /artifact/:bookshareId
  # Upload a replacement for an existing artifact.
  #
  def update
    __debug_route
  end

  # == DELETE /artifact/:id
  # == DELETE /artifact/:bookshareId
  # Remove an existing artifact entry.
  #
  def destroy
    __debug_route
  end

  # == GET /artifact/:id/:fmt
  # == GET /artifact/:bookshareId/:fmt
  # Download an artifact of the indicated Bookshare format type.
  #
  def download
    __debug_route
    opt = { bookshareId: @bookshare_id, format: @format }
    render_download(:download_title, **opt)
  end

  # == GET /artifact/retrieval?url=URL
  # Retrieve a Bookshare artifact from an absolute URL (as found in EMMA
  # Unified Search results).
  #
  def retrieval
    __debug_route
    render_download(:get_retrieval, url: params[:url])
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [*] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { artifacts: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Bs::Record::ArtifactMetadata, Hash] item
  #
  # @return [Hash{Symbol=>Bs::Record::ArtifactMetadata,Hash}]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item)
    { artifact: item }
  end

end

__loading_end(__FILE__)
