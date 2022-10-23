# app/controllers/periodical_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/periodical" pages.
#
# @see PeriodicalDecorator
# @see PeriodicalsDecorator
# @see file:app/views/periodical/**
#
# @note These endpoints are not currently presented as a part of EMMA.
#
class PeriodicalController < ApplicationController

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

  before_action :set_bs_series, except: %i[index]

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /periodical
  #
  # List all periodicals.
  #
  # @see #periodical_index_path       Route helper
  # @see BookshareService::Request::Periodicals#get_periodicals
  #
  def index
    __debug_route
    err   = nil
    @page = pagination_setup
    opt   = @page.initial_parameters
    b_opt = opt.except(:format)
    @list = bs_api.get_periodicals(**b_opt)
    err   = @list.exec_report if @list.error?
    @page.finalize(@list, :periodicals, **opt)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :periodical) }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # == GET /periodical/:id
  #
  # Display details of an existing periodical.
  #
  # @see #periodical_path             Route helper
  # @see BookshareService::Request::Periodicals#get_periodical
  # @see BookshareService::Request::Periodicals#get_periodical_editions
  #
  def show
    __debug_route
    err   = nil
    @page = pagination_setup
    opt   = @page.initial_parameters
    b_opt = opt.except(:format).merge!(seriesId: bs_series)
    @item = bs_api.get_periodical(**b_opt)
    @list = bs_api.get_periodical_editions(**b_opt)
    err   = @item.exec_report if @item.error?
    err   = @list.exec_report if @list.error?
    @page.finalize(@list, :periodicalEditions, **opt)
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

  # == GET /periodical/new[?id=:id]
  #
  # Add metadata for a new periodical.
  #
  # @see #new_periodical_path         Route helper
  #
  def new
    __debug_route
  end

  # == POST /periodical/:id
  #
  # Create an entry for a new periodical.
  #
  # @see #periodical_path             Route helper
  #
  def create
    __debug_route
  end

  # == GET /periodical/:id/edit
  #
  # Modify metadata of an existing periodical entry.
  #
  # @see #edit_periodical_path        Route helper
  #
  def edit
    __debug_route
  end

  # == PUT   /periodical/:id
  # == PATCH /periodical/:id
  #
  # Update the entry for an existing periodical.
  #
  # @see #periodical_path             Route helper
  #
  def update
    __debug_route
  end

  # == DELETE /periodical/:id
  #
  # Remove an existing periodical entry.
  #
  # @see #periodical_path             Route helper
  #
  def destroy
    __debug_route
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Bs::Message::PeriodicalSeriesMetadataSummaryList] list
  # @param [Hash]                                             opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :periodicals)
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
    opt.reverse_merge!(name: :periodical)
    result ||= { details: @item, editions: @list }
    super(result, **opt)
  end

end

__loading_end(__FILE__)
