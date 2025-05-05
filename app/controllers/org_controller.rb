# app/controllers/org_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage organizations ("/org" pages).
#
# @see OrgDecorator
# @see OrgsDecorator
# @see file:app/views/org/**
#
class OrgController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include OrgConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource instance_name: :item

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  MENUS = %i[show_select edit_select delete_select].freeze
  OPS   = %i[new edit delete].freeze

  # None

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, except: [*MENUS, *OPS]

  # ===========================================================================
  # :section: Values
  # ===========================================================================

  public

  # Single item.
  #
  # @return [Org, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section: Constants
  # ===========================================================================

  public

  INDEX_PAGE = 'org/index'
  SHOW_PAGE  = 'org/show'
  EDIT_PAGE  = 'org/edit'

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /org
  #
  # List all organizations.
  #
  # @see #org_index_path          Route helper
  #
  def index
    __log_activity
    __debug_route
    id  = identifier || current_id
    prm = paginator.initial_parameters
    if id.blank? && prm.except(:sort, *Paginator::NON_SEARCH_KEYS).present?
      # Apply parameters to render a page of items.
      list_items(prm)
    else
      # If not performing a search, redirect to the appropriate view action.
      if id.blank?
        prm.merge!(action: :list_all)
      else
        prm.merge!(action: :show, id: id)
      end
      respond_to do |format|
        format.html { redirect_to prm }
        format.json { redirect_to prm.merge!(format: :json) }
        format.xml  { redirect_to prm.merge!(format: :xml) }
      end
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /org/show/(:id)
  #
  # Display details of an existing EMMA member organization.
  #
  # Redirects to #show_select if :id is not given.
  # Redirects to #show_current if :id is #CURRENT_ID.
  #
  # @see #show_org_path          Route helper
  #
  def show
    __log_activity
    __debug_route
    return redirect_to action: :show_select              if identifier.blank?
    return redirect_to without_id(action: :show_current) if current_id?
    @item = find_record
    raise config_term(:org, :not_found, id: identifier)  if @item.blank?
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, show_select_org_path)
  end

  # === GET /org/new
  #
  # @see #new_org_path           Route helper
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

  # === POST  /org/create
  # === PUT   /org/create
  # === PATCH /org/create
  #
  # @see #create_org_path                     Route helper
  #
  def create
    redir = post_redirect
    __log_activity
    __debug_route
    @item = create_record
    generate_new_org_emails(@item) if new_org_email?
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

  # === GET /org/edit/(:id)
  #
  # Display a form for modification of an existing EMMA member organization.
  #
  # Redirects to #edit_select if :id is not given.
  # Redirects to #edit_current if :id is #CURRENT_ID.
  #
  # @see #edit_org_path          Route helper
  #
  def edit
    __log_activity
    __debug_route
    return redirect_to action: :edit_select              if identifier.blank?
    return redirect_to without_id(action: :edit_current) if current_id?
    @item = edit_record
    raise config_term(:org, :not_found, id: identifier)  if @item.blank?
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, edit_select_org_path)
  end

  # === POST  /org/update/:id
  # === PUT   /org/update/:id
  # === PATCH /org/update/:id
  #
  # @see #update_org_path                     Route helper
  #
  def update
    redir = post_redirect(edit_select_org_path)
    __log_activity
    __debug_route
    __debug_request
    @item = update_record
    generate_new_org_emails(@item) if new_org_email?
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: redir)
    end
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error, redirect: redir)
  rescue Record::SubmitError => error
    post_response(:conflict, error, redirect: redir)
  rescue => error
    post_response(error, redirect: redir)
  end

  # === GET /org/delete/(:id)
  #
  # Redirects to #delete_select if :id is not given.
  #
  # @see #delete_org_path           Route helper
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    raise config_term(:org, :self_delete)     if current_id?
    @list = delete_records.list&.records
    unless @list.present? || last_operation_path&.include?('/destroy')
      raise config_term(:org, :no_match, id: identifier_list)
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, delete_select_org_path)
  end

  # === DELETE /org/destroy/:id
  #
  # @see #destroy_org_path            Route helper
  #
  def destroy
    redir = post_redirect(delete_select_org_path)
    __log_activity
    __debug_route
    raise config_term(:org, :self_delete) if current_id?
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

  # === GET /org/list_all
  #
  # List all organizations.
  #
  # @see OrgController#list_items
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
  rescue Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # ===========================================================================
  # :section: Routes - List
  # ===========================================================================

  protected

  # Setup pagination for lists of organizations.
  #
  # @param [Hash, nil] prm            Default: from `paginator`.
  #
  # @return [Hash]
  #
  def list_items(prm = nil)
    prm ||= paginator.initial_parameters
    items = find_or_match_records(**prm)
    paginator.finalize(items, **prm)
    prm
  end

  # ===========================================================================
  # :section: Routes - Current
  # ===========================================================================

  public

  # === GET /org/show_current
  #
  # Display details of the current EMMA member organization.
  #
  # @see #show_current_org_path       Route helper
  #
  def show_current
    __log_activity
    __debug_route
    @item = current_org #or redirect_to action: :show_select
    respond_to do |format|
      format.html { render SHOW_PAGE }
      format.json { render SHOW_PAGE }
      format.xml  { render SHOW_PAGE }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    if params[:format] == :html
      error_response(error, org_index_path)
    else
      failure_status(error, status: :bad_request)
    end
  end

  # === GET /org/edit_current
  #
  # Display a form for modification of the current user's EMMA member
  # organization.
  #
  # @see #edit_current_org_path       Route helper
  #
  def edit_current
    __log_activity
    __debug_route
    @item = current_org or redirect_to action: :edit_select
    respond_to do |format|
      format.html { render EDIT_PAGE }
      format.json { render EDIT_PAGE }
      format.xml  { render EDIT_PAGE }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, org_index_path)
  end

  # ===========================================================================
  # :section: Routes - Menu
  # ===========================================================================

  public

  # === GET /org/show_select
  #
  # Show a menu to select an organization to show.
  #
  # @see #show_select_org_path        Route helper
  #
  def show_select
    __log_activity
    __debug_route
  end

  # === GET /org/edit_select
  #
  # Show a menu to select an organization to edit.
  #
  # @see #edit_select_org_path        Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # === GET /org/delete_select
  #
  # Show a menu to select an organization to delete.
  #
  # @see #delete_select_org_path      Route helper
  #
  def delete_select
    __log_activity
    __debug_route
  end

end

__loading_end(__FILE__)
