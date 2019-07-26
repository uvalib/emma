# app/controllers/reading_list_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ReadingListController
#
# @see ReadingListHelper
#
class ReadingListController < ApplicationController

  include ApiConcern
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern

  include ReadingListHelper

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

  before_action :initialize_service
  before_action { @id = params[:readingListId] || params[:id] }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /reading_list
  # List all reading lists available to the user (private lists, shared lists,
  # or organization list to which the user is subscribed).
  #
  def index
    __debug { "READING LIST #{__method__} | params = #{params.inspect}" }
    opt  = pagination_setup
    list = @api.get_my_reading_lists(**opt)
    self.page_items  = list.lists
    self.total_items = list.totalResults
    self.next_page   = next_page_path(list, opt)
  end

  # == GET /reading_list/:id
  # Display details of a reading list.
  #
  def show
    __debug { "READING LIST #{__method__} | params = #{params.inspect}" }
    @item = @api.get_reading_list(readingListId: @id)
    opt  = pagination_setup
    list = @api.get_reading_list_titles(readingListId: @id, **opt)
    self.page_items  = list.titles
    self.total_items = list.totalResults
    self.next_page   = next_page_path(list, opt)
  end

  # == GET /reading_list/new[?id=:id]
  # Add details for a new reading list.
  #
  def new
    __debug { "READING LIST #{__method__} | params = #{params.inspect}" }
    # TODO: get fields :name, :description, :access
  end

  # == POST /reading_list/:id
  # Create a new reading list.
  #
  def create
    __debug { "READING LIST #{__method__} | params = #{params.inspect}" }
    opt = params.slice(:name, :description, :access).to_unsafe_h
    @api.create_reading_list(name: opt[:name], **opt.except(:name))
  end

  # == GET /reading_list/:id/edit
  # Modify metadata of an existing reading list.
  #
  def edit
    __debug { "READING LIST #{__method__} | params = #{params.inspect}" }
    # TODO: modify fields :name, :description, :access, :titles
  end

  # == PUT   /reading_list/:id
  # == PATCH /reading_list/:id
  # Update the entry for an existing reading list.
  #
  def update
    __debug { "READING LIST #{__method__} | params = #{params.inspect}" }
    Array.wrap(params[:add_titles]).each do |bid|
      @api.create_reading_list_title(readingListId: @id, bookshareId: bid)
    end
    Array.wrap(params[:remove_titles]).each do |bid|
      @api.remove_reading_list_title(readingListId: @id, bookshareId: bid)
    end
    opt = params.slice(:name, :description, :access).to_unsafe_h
    @api.update_reading_list(readingListId: @id, **opt) if opt.present?
  end

  # == DELETE /reading_list/:id
  # Remove an existing reading list.
  #
  def destroy
    __debug { "READING LIST #{__method__} | params = #{params.inspect}" }
    # TODO: no API method; show Bookshare page
  end

end

__loading_end(__FILE__)
