# app/controllers/artifact_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare download requests.
#
# @see ArtifactDecorator
# @see ArtifactsDecorator
# @see file:app/views/artifact/**
#
# @note These endpoints are not currently presented as a part of EMMA.
#
# == Usage Notes
# The abilities to retrieve or modify artifacts (instances of remediated
# content) is dependent on the role(s) of the authenticated user.
#
class ArtifactController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include SerializationConcern
  include BookshareConcern
  include BsDownloadConcern

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
  before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_bs_id,             except: %i[index]
  before_action :set_bs_format,         except: %i[retrieval]
  before_action :set_bs_member,         only:   %i[download retrieval]
  before_action :set_item_download_url, only:   %i[retrieval]

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
    @page = pagination_setup
    opt   = @page.initial_parameters
    @list = bs_api.get_artifact_list(**opt)
    @page.finalize(@list, :artifacts, **opt)
    flash_now_alert(@list.exec_report) if @list.error?
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :artifact) }
    end
  end
=end

  # == GET /artifact/:id?fmt=:fmt
  # == GET /artifact/:bookshareId?fmt=:fmt
  #
  # Get metadata for an existing artifact.
  #
  # @see #artifact_path               Route helper
  # @see BookshareService::Request::Titles#get_artifact_metadata
  #
  def show
    __debug_route
    opt   = { bookshareId: bs_id, format: bs_format }
    @item = bs_api.get_artifact_metadata(**opt)
    flash_now_alert(@item.exec_report) if @item.error?
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
  # @see #new_artifact_path           Route helper
  #
  def new
    __debug_route
  end

  # == POST /artifact/:id
  # == POST /artifact/:bookshareId
  #
  # Upload a new artifact.
  #
  # @see #create_artifact_path        Route helper
  #
  def create
    __debug_route
  end

  # == GET /artifact/:id/edit
  # == GET /artifact/:bookshareId/edit
  #
  # Modify metadata of an existing artifact entry.
  #
  # @see #edit_artifact_path          Route helper
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
  # @see #update_artifact_path        Route helper
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /artifact/:bookshareId/:fmt?member=BS_ACCOUNT_ID
  # == GET /artifact/:bookshareId/:fmt?forUser=BS_ACCOUNT_ID
  #
  # Download an artifact of the indicated Bookshare format type.
  #
  # @see #bs_download_path            Route helper
  # @see BookshareService::Request::Titles#download_title
  #
  def download
    __debug_route
    opt = { bookshareId: bs_id, format: bs_format, forUser: bs_member }
    bs_download_response(:download_title, **opt)
  end

  # == GET /artifact/retrieval?url=URL&forUser=BS_ACCOUNT_ID
  # == GET /artifact/retrieval?url=URL&member=BS_ACCOUNT_ID
  #
  # Retrieve a Bookshare artifact from an absolute URL (as found in EMMA
  # Unified Search results).
  #
  # @see #bs_retrieval_path           Route helper
  # @see BookshareService::Request::Titles#get_retrieval
  #
  def retrieval
    __debug_route
    opt = { url: item_download_url, forUser: bs_member }
    bs_download_response(:get_retrieval, **opt)
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Any]  list
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :artifacts)
    super(list, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Bs::Record::ArtifactMetadata, Hash] item
  # @param [Hash]                               opt
  #
  # @return [Hash{Symbol=>Bs::Record::ArtifactMetadata,Hash}]
  #
  def show_values(item = @item, **opt)
    opt.reverse_merge!(name: :artifact)
    super(item, **opt)
  end

end

__loading_end(__FILE__)
