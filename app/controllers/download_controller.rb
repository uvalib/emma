# app/controllers/download_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/downloads" requests for managing download event records.
#
# Unlike similar database record controllers, routes here use the plural
# "/downloads" to avoid conflict with the existing "/download" route.
#
# Currently, download event listings are only available to users with the
# "administrator" role.  Users with the "developer" role are configured to see
# controls for edit/delete operations, however these are largely untested.
#
# @see DownloadDecorator
# @see DownloadsDecorator
# @see file:app/views/download/**
#
class DownloadController < ApplicationController

  include UserConcern
  include SessionConcern
  include DownloadConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  ADMIN_OPS = %i[new create edit update delete destroy].freeze

  before_action :update_user
  before_action :authenticate_user!,  except: ADMIN_OPS
  before_action :authenticate_admin!, only:   ADMIN_OPS

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource instance_name: :item

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  MENUS = %i[show_select edit_select delete_select].freeze

  # None

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, except: MENUS

  # ===========================================================================
  # :section: Values
  # ===========================================================================

  public

  # Results for :index.
  #
  # @return [Array<Download,String>]
  # @return [Hash]
  # @return [nil]
  #
  attr_reader :list

  # API results for :show.
  #
  # @return [Download, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section: Constants
  # ===========================================================================

  public

  INDEX_PAGE = 'download/index'

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # == GET /downloads
  # == GET /downloads/index
  #
  # List download event records.
  #
  # @see #download_index_path         Route helper
  #
  def index
    __log_activity
    __debug_route
    prm   = paginator.initial_parameters
    items = find_or_match_records(**prm)
    paginator.finalize(items, **prm)
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error)
  end

  # === GET /downloads/show/(:id)
  #
  # Redirects to #show_select if `:id` is missing.
  #
  # @see #show_download_path          Route helper
  #
  def show
    __log_activity
    __debug_route
    return redirect_to action: :show_select if identifier.blank?
    @item = find_record
    respond_to do |format|
      format.html
      format.json #{ render_json show_values }
      format.xml  #{ render_xml  show_values }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /downloads/new
  #
  # @see #new_download_path           Route helper
  #
  def new
    __log_activity
    __debug_route
    @item = new_record
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    failure_status(error)
  end

  # === POST  /downloads/create
  # === PUT   /downloads/create
  # === PATCH /downloads/create
  #
  # Record creation due to "/downloads/new".
  #
  # @see #create_download_path        Route helper
  #
  def create
    __log_activity
    __debug_route
    create_action
  end

  # === GET /downloads/edit/(:id)
  #
  # Redirects to #edit_select if :id is not given.
  #
  # @see #edit_download_path          Route helper
  #
  def edit
    __log_activity
    __debug_route
    return redirect_to action: :edit_select if identifier.blank?
    @item = edit_record
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, edit_select_download_path)
  end

  # === POST  /downloads/update/:id
  # === PUT   /downloads/update/:id
  # === PATCH /downloads/update/:id
  #
  # @see #update_download_path        Route helper
  #
  def update
    redir = post_redirect(edit_select_download_path)
    __log_activity
    __debug_route
    __debug_request
    @item = update_record
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: redir)
    end
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /downloads/delete/(:id)
  #
  # Redirects to #delete_select if :id is not given.
  #
  # @see #delete_download_path          Route helper
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    @list = delete_records.list&.records
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, delete_select_download_path)
  end

  # === DELETE /downloads/delete/:id
  #
  # @see #destroy_download_path           Route helper
  #
  def destroy
    redir = post_redirect(delete_select_download_path)
    __log_activity
    __debug_route
    @list = destroy_records
    post_response(:ok, @list, redirect: redir)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    post_response(:conflict, error, redirect: redir)
  rescue => error
    post_response(error, redirect: redir)
  end

  # ===========================================================================
  # :section: Routes - List
  # ===========================================================================

  public

  # === GET /downloads/list_all
  #
  # List all download event records.
  #
  # @see DownloadController#list_items
  #
  def list_all
    __log_activity
    __debug_route
    list_items
    respond_to do |format|
      format.html { render INDEX_PAGE }
      format.json { render INDEX_PAGE }
      format.xml  { render INDEX_PAGE }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /manifest/list_org
  #
  # List all download event records associated with users in the same
  # organization as the current user.
  #
  # @see DownloadController#list_items
  #
  def list_org
    __log_activity
    __debug_route
    list_items(for_org: true)
    opt = { locals: { name: current_org&.label } }
    respond_to do |format|
      format.html { render INDEX_PAGE, **opt }
      format.json { render INDEX_PAGE, **opt }
      format.xml  { render INDEX_PAGE, **opt }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /manifest/list_own
  #
  # List all download event records associated with the current user.
  #
  # @see DownloadController#list_items
  #
  def list_own
    __log_activity
    __debug_route
    list_items(for_user: true)
    respond_to do |format|
      format.html { render INDEX_PAGE }
      format.json { render INDEX_PAGE }
      format.xml  { render INDEX_PAGE }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # ===========================================================================
  # :section: Routes - List
  # ===========================================================================

  protected

  # Setup pagination for lists of download event records.
  #
  # @param [Hash, nil] prm            Default: from `paginator`.
  # @param [Boolean]   for_org
  # @param [Boolean]   for_user
  #
  # @return [Hash]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def list_items(prm = nil, for_org: false, for_user: false)
    prm ||= paginator.initial_parameters
    current_org!(prm)  if for_org
    current_user!(prm) if for_user
    items = find_or_match_records(**prm)
    paginator.finalize(items, **prm)
    # noinspection RubyMismatchedReturnType
    prm
  end

  # ===========================================================================
  # :section: Routes - Menu
  # ===========================================================================

  public

  # === GET /downloads/show_select
  #
  # Show a menu to select a download event to show.
  #
  # @see #show_select_download_path     Route helper
  #
  def show_select
    __log_activity
    __debug_route
  end

  # === GET /downloads/edit_select
  #
  # Show a menu to select a download event to edit.
  #
  # @see #edit_select_download_path     Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # === GET /downloads/delete_select
  #
  # Show a menu to select a download event to delete.
  #
  # @see #delete_select_download_path   Route helper
  #
  def delete_select
    __log_activity
    __debug_route
  end

  # ===========================================================================
  # :section: Routes - registration
  # ===========================================================================

  public

  # === POST /downloads/register
  #
  # Record creation due to client-side registration.
  #
  # @see #register_download_path      Route helper
  #
  def register
    __log_activity
    __debug_route
    create_action
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create a new download event record.
  #
  def create_action
    redir = post_redirect
    @item = create_record
    if request_xhr?
      render json: @item.as_json
    else
      post_response(@item, redirect: redir)
    end
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error, redirect: redir)
  rescue Record::SubmitError => error
    post_response(:conflict, error, redirect: redir)
  rescue => error
    post_response(error, redirect: redir)
  end

end

__loading_end(__FILE__)
