# app/controllers/title_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/title" pages.
#
# @see TitleDecorator
# @see TitlesDecorator
# @see file:app/views/title/**
#
# @note These endpoints are not currently presented as a part of EMMA.
#
class TitleController < ApplicationController

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
  before_action :authenticate_user!, except: %i[index show]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_bs_id, except: %i[index]

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /title
  #
  # List all catalog titles.
  #
  # @see #title_index_path            Route helper
  # @see BookshareService::Action::Titles#get_titles
  #
  def index
    __log_activity(anonymous: true)
    __debug_route
    err = nil
    prm = request_parameters

    if Isbn.candidate?((isbn = prm[:keyword]))
      # The search looks like an ISBN so interpret this as an ISBN search.
      prm[:isbn] = Isbn.to_isbn(isbn) || isbn
      prm.delete(:keyword)
      return redirect_to prm

    elsif (isbn = prm[:isbn]) && prm[:keyword]
      # Since the same input box is used for both ISBN and keyword searches,
      # if there's a non-ISBN keyword search then it must be replacing a
      # previous ISBN search (if there was one).
      prm.delete(:isbn)
      return redirect_to prm

    elsif isbn && !Isbn.valid?(isbn)
      # The supplied ISBN is not valid.
      prm.delete(:isbn)
      pagination_setup
      err   = "#{isbn.inspect} is not a valid ISBN" # TODO: I18n

    else
      # Search for keyword(s) or a valid ISBN.
      prm   = paginator.initial_parameters
      b_opt = bs_params(:start, :limit, **prm)
      @list = bs_api.get_titles(**b_opt)
      paginator.finalize(@list, :titles, **prm)
      err   = @list.exec_report if @list.error?
    end

    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :catalog_title) }
    end

  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # == GET /title/:id
  #
  # Display details of an existing catalog title.
  #
  # @see #title_path                  Route helper
  # @see BookshareService::Action::Titles#get_title
  #
  def show
    __log_activity(anonymous: true)
    __debug_route
    err   = nil
    b_opt = { bookshareId: bs_id }
    @item = bs_api.get_title(**b_opt)
    err   = @item.exec_report if @item.error?
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

  # == GET /title/new[?id=:id]
  #
  # Add metadata for a new catalog title.
  #
  # @see #new_title_path              Route helper
  #
  def new
    __log_activity
    __debug_route
  end

  # == POST /title/:id
  #
  # Create an entry for a new catalog title.
  #
  # @see #title_path                  Route helper
  #
  def create
    __log_activity
    __debug_route
  end

  # == GET /title/:id/edit
  #
  # Modify metadata of an existing catalog title entry.
  #
  # @see #edit_title_path             Route helper
  #
  def edit
    __log_activity
    __debug_route
  end

  # == PUT   /title/:id
  # == PATCH /title/:id
  #
  # Update the entry for an existing catalog title.
  #
  # @see #title_path                  Route helper
  #
  def update
    __log_activity
    __debug_route
  end

  # == DELETE /title/:id
  #
  # Remove an existing catalog title entry.
  #
  # @see #title_path                  Route helper
  #
  def destroy
    __log_activity
    __debug_route
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /title/:id/history
  #
  # Show processing history for this catalog title.
  #
  # @see #history_title_path          Route helper
  #
  def history
    __debug_route
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Bs::Message::TitleMetadataSummaryList] list
  # @param [Hash]                                  opt
  #
  # @return [Hash{Symbol=>Bs::Message::TitleMetadataSummaryList,Hash}]
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :catalog_titles)
    super(list, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Bs::Message::TitleMetadataDetail, Hash] item
  # @param [Hash]                                   opt
  #
  # @return [Hash{Symbol=>Bs::Message::TitleMetadataDetail,Hash}]
  #
  def show_values(item = @item, **opt)
    opt.reverse_merge!(name: :catalog_title)
    super(item, **opt)
  end

end

__loading_end(__FILE__)
