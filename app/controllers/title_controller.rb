# app/controllers/title_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# TitleController
#
# @see TitleHelper
#
class TitleController < ApplicationController

  include ApiConcern
  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern

  include TitleHelper
  include IsbnHelper

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

  before_action { @bookshare_id = params[:bookshareId] || params[:id] }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /title
  # List all catalog titles.
  #
  def index
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
    opt = request_parameters
    if contains_isbn?(opt[:keyword])
      # The search looks like an ISBN so interpret this as an ISBN search.
      isbn = opt.delete(:keyword)
      opt[:isbn] = to_isbn(isbn) || isbn
      return redirect_to opt
    elsif (isbn = opt[:isbn]) && opt[:keyword]
      # Since the same input box is used for both ISBN and keyword searches,
      # if there's a non-ISBN keyword search then it must be replacing a
      # previous ISBN search (if there was one).
      opt.delete(:isbn)
      return redirect_to opt
    elsif isbn && !isbn?(isbn)
      # The supplied ISBN is not valid.
      flash.now[:notice] = "#{isbn.inspect} is not a valid ISBN"
      opt.delete(:isbn)
      @list = []
    else
      # Search for keyword(s) or a valid ISBN.
      opt   = pagination_setup(opt)
      @list = api.get_titles(**opt)
      self.page_items  = @list.titles
      self.total_items = @list.totalResults
      self.next_page   = next_page_path(@list, opt)
    end
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  end

  # == GET /title/:id
  # Display details of an existing catalog title.
  #
  def show
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
    @item = api.get_title(bookshareId: @bookshare_id)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  end

  # == GET /title/new[?id=:id]
  # Add metadata for a new catalog title.
  #
  def new
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == POST /title/:id
  # Create an entry for a new catalog title.
  #
  def create
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == GET /title/:id/edit
  # Modify metadata of an existing catalog title entry.
  #
  def edit
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == PUT   /title/:id
  # == PATCH /title/:id
  # Update the entry for an existing catalog title.
  #
  def update
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == DELETE /title/:id
  # Remove an existing catalog title entry.
  #
  def destroy
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # == GET /title/:id/history
  # Show processing history for this catalog title.
  #
  def history
    __debug { "TITLE #{__method__} | params = #{params.inspect}" }
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [ApiTitleMetadataSummaryList, nil] list
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#index_values
  #
  def index_values(list = @list)
    { catalog_titles: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [ApiTitleMetadataDetail, nil] item
  # @param [Symbol]                      as     Unused.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see SerializationConcern#show_values
  #
  def show_values(item = @item, as: nil)
    { catalog_title: item }
  end

end

__loading_end(__FILE__)
