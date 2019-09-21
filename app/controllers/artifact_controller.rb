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

  include ApiConcern
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include DownloadConcern

  include ArtifactHelper

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :authenticate_user!
  before_action :update_user

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action { @bookshare_id = params[:bookshareId] || params[:id] }
  before_action { @format = params[:fmt] || Api::FormatType.new.default }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # TODO: all artifacts? Probably not...
  # == GET /artifact
  # List all artifacts.
  #
  def index
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
    opt   = pagination_setup
    @list = api.get_organization_members(**opt)
    self.page_items  = @list.userAccounts
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
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
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
    @item =
      api.get_artifact_metadata(bookshareId: @bookshare_id, format: @format)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /artifact/new[?id=:id]
  # == GET /artifact/new[?bookshareId=:bookshareId]
  # Add metadata for a new artifact.
  #
  def new
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == POST /artifact/:id
  # == POST /artifact/:bookshareId
  # Upload a new artifact.
  #
  def create
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == GET /artifact/:id/edit
  # == GET /artifact/:bookshareId/edit
  # Modify metadata of an existing artifact entry.
  #
  def edit
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == PUT   /artifact/:id
  # == PUT   /artifact/:bookshareId
  # == PATCH /artifact/:id
  # == PATCH /artifact/:bookshareId
  # Upload a replacement for an existing artifact.
  #
  def update
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == DELETE /artifact/:id
  # == DELETE /artifact/:bookshareId
  # Remove an existing artifact entry.
  #
  def destroy
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
  end

  # == GET /artifact/:id/:fmt
  # == GET /artifact/:bookshareId/:fmt
  # Download an artifact of the indicated Bookshare format type.
  #
  def download
    __debug { "ARTIFACT #{__method__} | params = #{params.inspect}" }
    opt = { bookshareId: @bookshare_id, format: @format }
    render_download api.download_title(**opt)
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [*, nil] list
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { artifacts: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Api::ArtifactMetadata, nil] item
  # @param [Symbol]                     as    Unused.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item, as: nil)
    { artifact: item }
  end

end

__loading_end(__FILE__)
