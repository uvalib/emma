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

  # None

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  OPS   = %i[new edit delete].freeze
  MENUS = %i[show_select edit_select delete_select].freeze

  respond_to :html
  respond_to :json, :xml, except: OPS + MENUS

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
    return redirect_to action: :show_select  if identifier.blank?
    return redirect_to action: :show_current if current_id?
    @item = find_record
    org_authorize!
    raise config_text(:org, :not_found, id: identifier) if @item.blank?
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
    org_authorize!
  rescue => error
    failure_status(error)
  end

  # === POST  /org/create
  # === PUT   /org/create
  # === PATCH /org/create
  #
  # @see #create_org_path        Route helper
  #
  def create
    __log_activity
    __debug_route
    @item = create_record
    org_authorize!
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: org_index_path)
    end
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
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
    return redirect_to action: :edit_select  if identifier.blank?
    return redirect_to action: :edit_current if current_id?
    @item = find_record
    org_authorize!
    raise config_text(:org, :not_found, id: identifier) if @item.blank?
  rescue => error
    error_response(error, edit_select_org_path)
  end

  # === POST  /org/update/:id
  # === PUT   /org/update/:id
  # === PATCH /org/update/:id
  #
  # @see #update_org_path        Route helper
  #
  def update
    __log_activity
    __debug_route
    __debug_request
    @item = update_record
    org_authorize!
    if request_xhr?
      render json: @item.as_json
    else
      post_response(:ok, @item, redirect: org_index_path)
    end
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /org/delete/(:id)
  #
  # Redirects to #delete_select if :id is not given.
  #
  # @see #delete_org_path        Route helper
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    raise config_text(:org, :self_delete)     if current_id?
    @list = delete_records.list&.records
    #org_authorize!(@list) # TODO: authorize :delete
    unless @list.present? || last_operation_path&.include?('/destroy')
      raise config_text(:org, :no_match, id: identifier_list)
    end
  rescue => error
    error_response(error, delete_select_org_path)
  end

  # === DELETE /org/destroy/:id
  #
  # @see #destroy_org_path       Route helper
  #
  #--
  # noinspection RubyScope
  #++
  def destroy
    __log_activity
    __debug_route
    back  = delete_select_org_path
    raise config_text(:org, :self_delete) if current_id?
    @list = destroy_records
    #org_authorize!(@list) # TODO: authorize :destroy
    post_response(:ok, @list, redirect: back)
  rescue Record::SubmitError => error
    post_response(:conflict, error, redirect: back)
  rescue => error
    post_response(error, redirect: back)
  end

  # ===========================================================================
  # :section: Routes - List
  # ===========================================================================

  public

  # === GET /org/list_all
  #
  # List all organizations.
  #
  def list_all
    __log_activity
    __debug_route
    list_items
    respond_to do |format|
      format.html { render 'org/index' }
      format.json { render 'org/index' }
      format.xml  { render 'org/index' }
    end
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
    # noinspection RubyMismatchedReturnType
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
    org_authorize!
    respond_to do |format|
      format.html { render 'org/show' }
      format.json { render 'org/show' }
      format.xml  { render 'org/show' }
    end
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
    org_authorize!
    respond_to do |format|
      format.html { render 'org/edit' }
      format.json { render 'org/edit' }
      format.xml  { render 'org/edit' }
    end
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether request parameters (explicitly or implicitly) reference
  # the current user's organization.
  #
  def current_id?
    id = identifier.presence&.to_s or return current_org.present?
    CURRENT_ID.casecmp?(id) || (id == current_id.to_s)
  end

  # This is a kludge until I can figure out the right way to express this with
  # CanCan -- or replace CanCan with a more expressive authorization gem.
  #
  # @param [Org, Array<Org>, nil] subject
  # @param [Symbol, String, nil]  action
  # @param [any, nil]             args
  #
  def org_authorize!(subject = nil, action = nil, *args)
    action  ||= request_parameters[:action]
    action    = action.to_sym if action.is_a?(String)
    subject ||= @item
    subject   = subject.first if subject.is_a?(Array) # TODO: per item check
    # noinspection RubyMismatchedArgumentType
    authorize!(action, subject, *args) if subject
    return if administrator?
    return unless %i[show edit update delete destroy].include?(action)
    unless (org = current_id) && (subject&.id == org)
      message = current_ability.unauthorized_message(action, subject)
      message.sub!(/s\.?$/, " #{subject.id}") if subject
      raise CanCan::AccessDenied.new(message, action, subject, args)
    end
  end

end

__loading_end(__FILE__)
