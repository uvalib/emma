# app/controllers/reading_list_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/reading_list" pages.
#
# @see ReadingListDecorator
# @see ReadingListsDecorator
# @see file:app/views/reading_list/**
#
# @note These endpoints are not currently presented as a part of EMMA.
#
class ReadingListController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include SerializationConcern
  include BookshareConcern

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

  before_action :set_bs_list, except: %i[index]

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /reading_list
  #
  # List all reading lists available to the user (private lists, shared lists,
  # or organization list to which the user is subscribed).
  #
  # @see #reading_list_index_path     Route helper
  # @see BookshareService::Request::ReadingLists#get_reading_lists_list
  #
  def index
    __debug_route
    err   = nil
    prm   = paginator.initial_parameters
    b_opt = bs_params(**prm)
    @list = bs_api.get_reading_lists_list(**b_opt)
    err   = @list.exec_report if @list.error?
    paginator.finalize(@list, :lists, **prm)
    flash_now_alert(@list.exec_report) if @list.error?
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :reading_list) }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # == GET /reading_list/:id
  #
  # Display details of a reading list.
  #
  # @see #reading_list_path           Route helper
  # @see BookshareService::Request::ReadingLists#get_reading_list
  # @see BookshareService::Request::ReadingLists#get_reading_list_titles
  #
  def show
    __debug_route
    err   = nil
    prm   = paginator.initial_parameters
    b_opt = { readingListId: bs_list }
    @item = bs_api.get_reading_list(**b_opt)
    @list = bs_api.get_reading_list_titles(**b_opt, no_raise: true)
    err   = @item.exec_report if @item.error?
    err   = @list.exec_report if @list.error?
    paginator.finalize(@list, :titles, **prm)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values(nil, as: :array) }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # == GET /reading_list/new[?id=:id]
  #
  # Add details for a new reading list.
  #
  # @see #new_reading_list_path       Route helper
  #
  def new
    __debug_route
    # TODO: get fields :name, :description, :access
  end

  # == POST /reading_list/:id
  #
  # Create a new reading list.
  #
  # @see #reading_list_path           Route helper
  #
  def create
    __debug_route
    prm = request_parameters.slice(:name, :description, :access)
    bs_api.create_my_reading_list(**prm)
  end

  # == GET /reading_list/:id/edit
  #
  # Modify metadata of an existing reading list.
  #
  # @see #edit_reading_list_path      Route helper
  #
  def edit
    __debug_route
    # TODO: modify fields :name, :description, :access, :titles
  end

  # == PUT   /reading_list/:id
  # == PATCH /reading_list/:id
  #
  # Update the entry for an existing reading list.
  #
  # @see #reading_list_path           Route helper
  #
  def update
    __debug_route
    prm   = request_parameters
    b_opt = { readingListId: bs_list }
    Array.wrap(prm[:add_titles]).each do |bid|
      bs_api.create_reading_list_title(**b_opt, bookshareId: bid)
    end
    Array.wrap(prm[:remove_titles]).each do |bid|
      bs_api.remove_reading_list_title(**b_opt, bookshareId: bid)
    end
    prm.slice!(:name, :description, :access)
    bs_api.update_reading_list(**b_opt, **prm) if prm.present?
  end

  # == DELETE /reading_list/:id
  #
  # Remove an existing reading list.
  #
  # @see #reading_list_path           Route helper
  #
  def destroy
    __debug_route
    # TODO: no API method; show Bookshare page
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Bs::Message::ReadingListList] list
  # @param [Hash]                         opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :reading_lists)
    super(list, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Hash, nil] result
  # @param [Hash]      opt
  #
  # @return [Hash{Symbol=>Hash,Array}]
  #
  def show_values(result = nil, **opt)
    opt.reverse_merge!(name: :reading_list)
    result ||= { details: @item, titles: @list }
    super(result, **opt)
  end

end

__loading_end(__FILE__)
