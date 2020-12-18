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
  include BsDownloadConcern

  # Non-functional hints for RubyMine type checking.
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

  before_action :set_bookshare_id
  before_action :set_format,        except: %i[retrieval]
  before_action :set_member,        only:   %i[download retrieval]
  before_action :set_url,           only:   %i[retrieval]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin # TODO: all artifacts? Probably not...
  # == GET /artifact
  #
  # List all artifacts.
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = bs_api.get_artifact_list(**opt)
    self.page_items  = @list.artifacts
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
  #
  # Get metadata for an existing artifact.
  #
  def show
    __debug_route
    opt   = { bookshareId: @bookshare_id, format: @format }
    @item = bs_api.get_artifact_metadata(**opt)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /artifact/new[?id=:id]
  # == GET /artifact/new[?bookshareId=:bookshareId]
  #
  # Add metadata for a new artifact.
  #
  def new
    __debug_route
  end

  # == POST /artifact/:id
  # == POST /artifact/:bookshareId
  #
  # Upload a new artifact.
  #
  def create
    __debug_route
  end

  # == GET /artifact/:id/edit
  # == GET /artifact/:bookshareId/edit
  #
  # Modify metadata of an existing artifact entry.
  #
  def edit
    __debug_route
  end

  # == PUT   /artifact/:id
  # == PUT   /artifact/:bookshareId
  # == PATCH /artifact/:id
  # == PATCH /artifact/:bookshareId
  #
  # Upload a replacement for an existing artifact.
  #
  def update
    __debug_route
  end

  # == DELETE /artifact/:id
  # == DELETE /artifact/:bookshareId
  #
  # Remove an existing artifact entry.
  #
  def destroy
    __debug_route
  end

  # == GET /artifact/:bookshareId/:fmt?member=BS_ACCOUNT_ID
  # == GET /artifact/:bookshareId/:fmt?forUser=BS_ACCOUNT_ID
  #
  # Download an artifact of the indicated Bookshare format type.
  #
  def download
    __debug_route
    opt = { bookshareId: @bookshare_id, format: @format, forUser: @member }
    bs_download_response(:download_title, **opt)
  end

  # == GET /artifact/retrieval?url=URL&forUser=BS_ACCOUNT_ID
  # == GET /artifact/retrieval?url=URL&member=BS_ACCOUNT_ID
  #
  # Retrieve a Bookshare artifact from an absolute URL (as found in EMMA
  # Unified Search results).
  #
  def retrieval
    __debug_route
    opt = { url: @url, forUser: @member }
    bs_download_response(:get_retrieval, **opt)
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
  def index_values(list = @list)
    { artifacts: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Bs::Record::ArtifactMetadata, Hash] item
  #
  # @return [Hash{Symbol=>Bs::Record::ArtifactMetadata,Hash}]
  #
  def show_values(item = @item, **)
    { artifact: item }
  end

end

__loading_end(__FILE__)
