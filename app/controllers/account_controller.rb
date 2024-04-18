# app/controllers/account_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Manage user accounts as represented in the User table ("/account" pages).
#
# @see AccountDecorator
# @see AccountsDecorator
# @see file:app/views/account/**
#
class AccountController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include AccountConcern

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource instance_name: :item, class: User

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  LISTS = %i[index list_all list_org].freeze
  SHOW  = %i[show show_current].freeze

  # None

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, only: [*SHOW, *LISTS]

  # ===========================================================================
  # :section: Values
  # ===========================================================================

  public

  # Database results for :show.
  #
  # @return [User, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /account
  #
  # List user accounts.
  #
  # @see #users_path                  Route helper
  # @see #account_index_path          Route helper
  # @see AccountConcern#get_accounts
  #
  def index
    __log_activity
    __debug_route
    prm = paginator.initial_parameters
    if prm.except(:sort, *Paginator::NON_SEARCH_KEYS).present?
      # Apply parameters to render a page of items.
      list_items(prm)
    else
      # If not performing a search, redirect to the appropriate view action.
      prm[:action] = current_org ? :list_org : :list_all
      respond_to do |format|
        format.html { redirect_to prm }
        format.json { redirect_to prm.merge!(format: :json) }
        format.xml  { redirect_to prm.merge!(format: :xml) }
      end
    end
  end

  # === GET /account/show/(:id)
  #
  # Display details of an existing EMMA user account.
  #
  # Redirects to #show_select if :id is not given.
  # Redirects to #show_current if :id is #CURRENT_ID.
  #
  # @see #show_account_path           Route helper
  #
  def show
    __log_activity
    __debug_route
    return redirect_to action: :show_select              if identifier.blank?
    return redirect_to without_id(action: :show_current) if current_id?
    @item = find_record
    raise config_text(:account, :not_found, id: identifier) if @item.blank?
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, show_select_account_path)
  end

  # === GET /account/new
  #
  # Display a form for creation of a new EMMA user account.
  #
  # For the deployed production application, a welcome email is generated for
  # the new user unless "welcome=false" appears in URL parameters.
  # Otherwise, a welcome email is generated *only* if "welcome=true" appears
  # in URL parameters.
  #
  # This parameter (if provided) is passed to the :create endpoint via a hidden
  # form parameter.
  #
  # @see #new_account_path            Route helper
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

  # === POST  /account/create
  # === PUT   /account/create
  # === PATCH /account/create
  #
  # Create a new EMMA user account.
  #
  # For the deployed production application, a welcome email is generated for
  # the new user unless "welcome=false" appears in the form parameters.
  #
  # Otherwise, a welcome email is generated *only* if "welcome=true" appears
  # in the form parameters.
  #
  # === Usage Notes
  # In order to allow the database to auto-generate the record ID, the :id
  # parameter will be rejected unless "force=true" is included in the URL
  # parameters (administrator only).
  #
  # @see #create_account_path         Route helper
  #
  def create
    __log_activity
    __debug_route
    mail  = params[:welcome]
    mail  = production_deployment? ? !false?(mail) : true?(mail)
    @item = create_record
    generate_welcome_email(item: @item) if mail
    post_response(:created, @item)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /account/edit/(:id)
  #
  # Display a form for modification of an existing EMMA user account.
  #
  # Redirects to #edit_select if :id is not given.
  # Redirects to #edit_current if :id is #CURRENT_ID.
  #
  # @see #edit_account_path           Route helper
  #
  def edit
    __log_activity
    __debug_route
    return redirect_to action: :edit_select               if identifier.blank?
    return redirect_to without_id(action: :edit_current)  if current_id?
    @item = edit_record
    raise config_text(:account, :not_found, id: identifier) if @item.blank?
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, edit_select_account_path)
  end

  # === PUT   /account/update/:id
  # === PATCH /account/update/:id
  #
  # Update an existing EMMA user account.
  #
  # @see #update_account_path         Route helper
  #
  def update
    __log_activity
    __debug_route
    __debug_request
    @item = update_record
    post_response(:ok, @item)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue => error
    post_response(error, redirect: edit_select_account_path)
  end

  # === GET /account/delete/(:id)
  #
  # Select existing EMMA user account(s) to remove.
  #
  # Redirects to #delete_select if :id is not given.
  #
  # @see #delete_account_path         Route helper
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    raise config_text(:account, :self_delete) if current_id?
    @list = delete_records.list&.records
    unless @list.present? || last_operation_path&.include?('/destroy')
      raise config_text(:account, :no_match, id: identifier_list)
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, delete_select_account_path)
  end

  # === DELETE /account/destroy/:id
  #
  # Remove existing EMMA user account(s).
  #
  # @see #destroy_account_path        Route helper
  #
  def destroy(back: delete_select_account_path)
    __log_activity
    __debug_route
    raise config_text(:account, :self_delete) if current_id?
    @list = destroy_records
    post_response(:ok, @list, redirect: back)
  rescue CanCan::AccessDenied => error
    post_response(:forbidden, error)
  rescue Record::SubmitError => error
    post_response(:conflict, error, redirect: back)
  rescue => error
    post_response(error, redirect: back)
  end

  # ===========================================================================
  # :section: Routes - List
  # ===========================================================================

  public

  # === GET /account/list_all
  #
  # List all user accounts.
  #
  def list_all
    __log_activity
    __debug_route
    list_items
    respond_to do |format|
      format.html { render 'account/index' }
      format.json { render 'account/index' }
      format.xml  { render 'account/index' }
    end
  end

  # === GET /account/list_org
  #
  # List all user accounts in the same organization as the current user.
  #
  def list_org
    __log_activity
    __debug_route
    list_items(for_org: true)
    opt = { locals: { name: current_org&.label } }
    respond_to do |format|
      format.html { render 'account/index', **opt }
      format.json { render 'account/index', **opt }
      format.xml  { render 'account/index', **opt }
    end
  end

  # ===========================================================================
  # :section: Routes - List
  # ===========================================================================

  protected

  # Setup pagination for lists of accounts.
  #
  # @param [Hash, nil] prm            Default: from `paginator`.
  # @param [Boolean]   for_org
  #
  # @return [Hash]
  #
  def list_items(prm = nil, for_org: false)
    prm ||= paginator.initial_parameters
    # noinspection RubyMismatchedArgumentType
    current_org!(prm) if for_org
    terms = prm.delete(:like)
    items = get_accounts(*terms, **prm)
    paginator.finalize(items, **prm)
    # noinspection RubyMismatchedReturnType
    prm
  end

  # ===========================================================================
  # :section: Routes - Current
  # ===========================================================================

  public

  # === GET /account/show_current
  #
  # Display details of the current EMMA user account.
  #
  # @see #show_current_account_path   Route helper
  #
  def show_current
    __log_activity
    __debug_route
    return redirect_to action: :show if identifier.present?
    @item = find_record(current_id)
    raise config_text(:account, :not_found, id: identifier) if @item.blank?
    respond_to do |format|
      format.html { render 'account/show' }
      format.json { render 'account/show' }
      format.xml  { render 'account/show' }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, account_index_path)
  end

  # === GET /account/edit_current
  #
  # Display a form for modification of the current EMMA user account.
  #
  # @see #edit_current_account_path   Route helper
  #
  def edit_current
    __log_activity
    __debug_route
    return redirect_to action: :edit if identifier.present?
    @item = edit_record(current_id)
    raise config_text(:account, :not_found, id: identifier) if @item.blank?
    respond_to do |format|
      format.html { render 'account/edit' }
      format.json { render 'account/edit' }
      format.xml  { render 'account/edit' }
    end
  rescue CanCan::AccessDenied => error
    error_response(error)
  rescue => error
    error_response(error, account_index_path)
  end

  # ===========================================================================
  # :section: Routes - Menu
  # ===========================================================================

  public

  # === GET /account/show_select
  #
  # Show a menu to select a user to show.
  #
  # @see #show_select_account_path    Route helper
  #
  def show_select
    __log_activity
    __debug_route
  end

  # === GET /account/edit_select
  #
  # Show a menu to select a user to edit.
  #
  # @see #edit_select_account_path    Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # === GET /account/delete_select
  #
  # Show a menu to select a user to delete.
  #
  # @see #delete_select_account_path  Route helper
  #
  def delete_select
    __log_activity
    __debug_route
  end

end

__loading_end(__FILE__)
