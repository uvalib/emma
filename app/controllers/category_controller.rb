# app/controllers/category_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle Bookshare-only "/category" pages.
#
# @see CategoryDecorator
# @see CategoriesDecorator
# @see file:app/views/category/**
#
# @note These endpoints are not currently presented as a part of EMMA.
#
# == Usage Notes
# Categories can be seen by anyone, including anonymous users.
#
class CategoryController < ApplicationController

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

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html, :json, :xml

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /category
  #
  # List all categories.
  #
  # @see #category_index_path         Route helper
  # @see BookshareService::Request::Titles#get_categories
  #
  def index
    __log_activity(anonymous: true)
    __debug_route
    err   = nil
    prm   = paginator.initial_parameters
    b_opt = bs_params(:start, :limit, **prm)
    @list = bs_api.get_categories(**b_opt)
    err   = @list.exec_report if @list.error?
    paginator.finalize(@list, :categories, **prm)
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :category) }
    end
  rescue => error
    err = error
  ensure
    failure_status(err)
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Bs::Message::CategoriesList] list
  # @param [Hash]                        opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :categories)
    super(list, **opt)
  end

end

__loading_end(__FILE__)
