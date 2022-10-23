# app/controllers/edition_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/edition" pages.
#
# @see EditionDecorator
# @see EditionsDecorator
# @see file:app/views/edition/**
#
# @note These endpoints are not currently presented as a part of EMMA.
#
# == Usage Notes
# The abilities to retrieve or modify editions (instances of remediated
# content) is dependent on the role(s) of the authenticated user.
#
class EditionController < ApplicationController

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
  before_action :authenticate_user!, except: %i[index show]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_bs_series
  before_action :set_bs_edition, except: %i[index]
  before_action :set_bs_format
  before_action :set_bs_member,  only:   %i[download]

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /edition?seriesId=:seriesId
  #
  # List all editions for a periodical.
  #
  # @see #edition_index_path          Route helper
  # @see BookshareService::Request::Periodicals#get_periodical_editions
  #
  def index
    __debug_route
    err   = nil
    @page = pagination_setup
    opt   = @page.initial_parameters
    b_opt = opt.except(:format).merge!(seriesId: bs_series)
    @list = bs_api.get_periodical_editions(**b_opt)
    err   = @list.exec_report if @list.error?
    @page.finalize(@list, :periodicalEditions, **opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :edition) }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # == GET /edition/:id?seriesId=:seriesId
  # == GET /edition/:editionId?seriesId=:seriesId
  #
  # Display details of an existing edition.
  #
  # @see #edition_path                Route helper
  # @see BookshareService::Request::Periodicals#get_periodical_edition
  #
  def show
    __debug_route
    err   = nil
    b_opt = { seriesId: bs_series, editionId: bs_edition }
    @item = bs_api.get_periodical_edition(**b_opt)
    err   = @item&.exec_report                            if @item&.error?
    err   = "Item #{bs_series}: no #{bs_edition} edition" if @item.nil?
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # == GET /edition/new[?id=:id]
  # == GET /edition/new[?editionId=:editionId]
  #
  # Add metadata for a new edition.
  #
  # @see #new_edition_path            Route helper
  #
  def new
    __debug_route
  end

  # == POST /edition/:id
  # == POST /edition/:editionId
  #
  # Upload a new edition.
  #
  # @see #edition_path                Route helper
  #
  def create
    __debug_route
  end

  # == GET /edition/:id/edit
  # == GET /edition/:editionId/edit
  #
  # Modify metadata of an existing edition entry.
  #
  # @see #edit_edition_path           Route helper
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
  # @see #edition_path                Route helper
  #
  def update
    __debug_route
  end

  # == DELETE /edition/:id
  # == DELETE /edition/:editionId
  #
  # Remove an existing edition entry.
  #
  # @see #edition_path                Route helper
  #
  def destroy
    __debug_route
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /edition/:id/:fmt?seriesId=:seriesId&member=BS_ACCOUNT_ID
  # == GET /edition/:editionId/:fmt?seriesId=:seriesId&member=BS_ACCOUNT_ID
  #
  # Download a periodical edition.
  #
  # @see #edition_download_path
  # @see BookshareService::Request::Periodicals#download_periodical_edition
  #
  def download
    __debug_route
    opt = {
      seriesId:  bs_series,
      editionId: bs_edition,
      format:    bs_format,
      forUser:   bs_member
    }
    bs_download_response(:download_periodical_edition, **opt)
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Bs::Message::PeriodicalEditionList] list
  # @param [Hash]                               opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :editions)
    super(list, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Bs::Record::PeriodicalEdition, Hash] item
  # @param [Hash]                                opt
  #
  # @return [Hash{Symbol=>Bs::Record::PeriodicalEdition,Hash}]
  #
  def show_values(item = @item, **opt)
    opt.reverse_merge!(name: :edition)
    super(item, **opt)
  end

end

__loading_end(__FILE__)
