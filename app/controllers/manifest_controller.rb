# app/controllers/manifest_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage bulk operation manifests
#
# @see ManifestDecorator
# @see ManifestsDecorator
# @see file:app/views/manifest/**
#
class ManifestController < ApplicationController

  include UserConcern
  include ParamsConcern
  include OptionsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include SerializationConcern
  include ManifestConcern

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include AbstractController::Callbacks
    include ActionController::RespondWith
    extend  CanCan::ControllerAdditions::ClassMethods
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

  # None

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, except: %i[edit]

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Results for :index.
  #
  # @return [Array<Manifest>]
  # @return [Array<String>]
  # @return [nil]
  #
  attr_reader :list

  # Single item.
  #
  # @return [Manifest, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /manifest
  #
  # List all of the user's manifests unless `params[:id]` is present (which
  # redirects to #edit).
  #
  # @see #manifest_index_path         Route helper
  #
  def index
    __log_activity
    __debug_route
    prm    = paginator.initial_parameters
    redirect_to prm.merge!(action: :edit) if identifier.present?
    result = find_or_match_manifests(**prm)
    @list  = paginator.finalize(result, **prm)
    respond_to do |format|
      format.html
      format.json #{ render_json index_values }
      format.xml  #{ render_xml  index_values }
    end
  rescue Record::SubmitError => error
    show_search_failure(error)
  rescue => error
    show_search_failure(error, root_path)
  end

  # == GET /manifest/show/:id
  #
  # @see #show_manifest_path          Route helper
  #
  def show
    __log_activity
    __debug_route
    @item = get_manifest
    respond_to do |format|
      format.html
      format.json #{ render_json show_values }
      format.xml  #{ render_xml  show_values }
    end
  rescue => error
    show_search_failure(error, root_path)
  end

  # == GET /manifest/new
  #
  # @see #new_manifest_path           Route helper
  #
  def new
    __log_activity
    __debug_route
    @item = new_manifest
  rescue => error
    failure_status(error)
  end

  # == POST  /manifest/create
  # == PUT   /manifest/create
  # == PATCH /manifest/create
  #
  # @see #create_manifest_path        Route helper
  #
  def create
    __log_activity
    __debug_route
    @item = create_manifest
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: manifest_index_path)
    end
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # == GET /manifest/edit/:id
  # == GET /manifest/edit/SELECT
  # == GET /manifest/edit_select
  #
  # @see #edit_manifest_path          Route helper
  # @see #edit_select_manifest_path   Route helper
  #
  def edit
    __log_activity
    __debug_route
    @item = (edit_manifest unless show_menu?)
  rescue => error
    failure_status(error)
  end

  # == POST  /manifest/update/:id
  # == PUT   /manifest/update/:id
  # == PATCH /manifest/update/:id
  #
  # @see #update_manifest_path        Route helper
  #
  def update
    __log_activity
    __debug_route
    __debug_request
    @item = update_manifest
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: manifest_index_path)
    end
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # == GET /manifest/delete/:id
  # == GET /manifest/delete_select
  #
  # @see #delete_manifest_path        Route helper
  # @see #delete_select_manifest_path Route helper
  #
  def delete
    __log_activity
    __debug_route
    @list = (delete_manifest[:list] unless show_menu?)
  rescue => error
    failure_status(error)
  end

  # == DELETE /manifest/destroy/:id
  #
  # @see #destroy_manifest_path       Route helper
  #
  #--
  # noinspection RubyScope
  #++
  def destroy
    __log_activity
    __debug_route
    back  = delete_select_manifest_path
    @list = destroy_manifest
    post_response(:ok, @list, redirect: back)
  rescue Record::SubmitError => error
    post_response(:conflict, error, redirect: back)
  rescue => error
    post_response(error, redirect: back)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == POST  /manifest/save/:id
  # == PUT   /manifest/save/:id
  # == PATCH /manifest/save/:id
  #
  # @see #save_manifest_path          Route helper
  # @see file:javascripts/controllers/manifest.js  *updateDataRow()*
  #
  def save
    __log_activity
    __debug_route
    @item = save_changes
    render_json save_response(columns: :row)
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # == POST  /manifest/cancel/:id
  # == PUT   /manifest/cancel/:id
  # == PATCH /manifest/cancel/:id
  #
  # @see #cancel_manifest_path        Route helper
  #
  def cancel
    __log_activity
    __debug_route
    @item = cancel_changes
    if request_xhr?
      render json: @item.as_json
    else
      # noinspection RubyMismatchedArgumentType
      redirect_to(params[:redirect] || manifest_index_path)
    end
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether URL parameters require that a menu should be shown rather
  # than operating on an explicit set of identifiers.
  #
  # @param [Array<String,Integer>] id_params  Def: `ManifestConcern#identifier`
  #
  def show_menu?(id_params = nil)
    Array.wrap(id_params || identifier).include?('SELECT')
  end

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # @param [Exception] error
  # @param [String]    fallback   Redirect fallback (def.: #entry_index_path).
  # @param [Symbol]    meth       Calling method.
  #
  # @return [void]
  #
  def show_search_failure(error, fallback = nil, meth: nil)
    re_raise_if_internal_exception(error)
    meth ||= calling_method
    if modal?
      failure_status(error, meth: meth)
    else
      flash_failure(error, meth: meth)
      redirect_back(fallback_location: (fallback || manifest_index_path))
    end
  end

  # A table of the Manifest's items transmitted when saving.
  #
  # @param [Manifest, nil]       item
  # @param [Symbol, String, nil] wrap
  # @param [Hash]                opt            Passed to Manifest#items_hash.
  #
  # @return [Hash{Symbol=>Hash{Integer=>Hash}}]
  # @return [Hash{Integer=>Hash}]               If *wrap* is *nil*.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def save_response(item = @item, wrap: :items, **opt)
    result = item.items_hash(**opt)
    result = { wrap.to_sym => result } if wrap
    result
  end

end

__loading_end(__FILE__)
