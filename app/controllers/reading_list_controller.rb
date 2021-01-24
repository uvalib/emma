# app/controllers/reading_list_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/reading_list" pages.
#
# @see ReadingListHelper
#
class ReadingListController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include BookshareConcern

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

  before_action :set_reading_list_id

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /reading_list
  #
  # List all reading lists available to the user (private lists, shared lists,
  # or organization list to which the user is subscribed).
  #
  def index
    __debug_route
    opt   = pagination_setup
    @list = bs_api.get_all_reading_lists(**opt)
    self.page_items  = @list.lists
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /reading_list/:id
  #
  # Display details of a reading list.
  #
  def show
    __debug_route
    @item = bs_api.get_reading_list(readingListId: @id)
    opt   = pagination_setup
    @list = bs_api.get_reading_list_titles(readingListId: @id, no_raise: true)
    self.page_items  = @list.titles
    self.total_items = @list.totalResults
    self.next_page   = next_page_path(@list, opt)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values(nil, as: :array) }
    end
  end

  # == GET /reading_list/new[?id=:id]
  #
  # Add details for a new reading list.
  #
  def new
    __debug_route
    # TODO: get fields :name, :description, :access
  end

  # == POST /reading_list/:id
  #
  # Create a new reading list.
  #
  def create
    __debug_route
    opt = params.slice(:name, :description, :access).to_unsafe_h
    bs_api.create_my_reading_list(**opt)
  end

  # == GET /reading_list/:id/edit
  #
  # Modify metadata of an existing reading list.
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
  def update
    __debug_route
    Array.wrap(params[:add_titles]).each do |bid|
      bs_api.create_reading_list_title(readingListId: @id, bookshareId: bid)
    end
    Array.wrap(params[:remove_titles]).each do |bid|
      bs_api.remove_reading_list_title(readingListId: @id, bookshareId: bid)
    end
    opt = params.slice(:name, :description, :access).to_unsafe_h
    bs_api.update_reading_list(readingListId: @id, **opt) if opt.present?
  end

  # == DELETE /reading_list/:id
  #
  # Remove an existing reading list.
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
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list)
    { reading_lists: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Hash, nil]   result
  # @param [Symbol, nil] as           Either :hash or :array if given.
  #
  # @return [Hash{Symbol=>Hash,Array}]
  #
  def show_values(result = nil, as: nil)
    result ||= { details: @item, titles: @list }
    { reading_list: super(result, as: as) }
  end

end

__loading_end(__FILE__)
