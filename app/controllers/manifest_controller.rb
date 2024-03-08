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

  authorize_resource instance_name: :item

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  # None

  # ===========================================================================
  # :section: Formats
  # ===========================================================================

  OPS   = %i[new edit delete remit].freeze
  MENUS = %i[show_select edit_select delete_select remit_select].freeze

  respond_to :html
  respond_to :json, :xml, except: OPS + MENUS

  # ===========================================================================
  # :section: Values
  # ===========================================================================

  public

  # Single item.
  #
  # @return [Manifest, nil]
  #
  attr_reader :item

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # === GET /manifest
  #
  # List bulk operation manifests.
  #
  # @see #manifest_index_path         Route helper
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
      prm[:action] = :list_own
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

  # === GET /manifest/show/(:id)
  #
  # Redirects to #show_select if :id is missing.
  #
  # @see #show_manifest_path          Route helper
  #
  def show
    __log_activity
    __debug_route
    return redirect_to action: :show_select if identifier.blank?
    @item = find_record
    manifest_authorize!
    respond_to do |format|
      format.html
      format.json #{ render_json show_values }
      format.xml  #{ render_xml  show_values }
    end
  rescue => error
    error_response(error, root_path)
  end

  # === GET /manifest/new
  #
  # @see #new_manifest_path           Route helper
  #
  def new
    __log_activity
    __debug_route
    @item = new_record
    manifest_authorize!
  rescue => error
    failure_status(error)
  end

  # === POST  /manifest/create
  # === PUT   /manifest/create
  # === PATCH /manifest/create
  #
  # @see #create_manifest_path        Route helper
  #
  def create
    __log_activity
    __debug_route
    @item = create_record
    manifest_authorize!
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

  # === GET /manifest/edit/(:id)
  #
  # Redirects to #edit_select if :id is not given.
  #
  # @see #edit_manifest_path          Route helper
  #
  def edit
    __log_activity
    __debug_route
    return redirect_to action: :edit_select if identifier.blank?
    @item = edit_record
    manifest_authorize!
    prm   = paginator.initial_parameters
    found = find_or_match_manifest_items(@item, **prm)
    paginator.finalize(found, **prm)
  rescue => error
    error_response(error, edit_select_manifest_path)
  end

  # === POST  /manifest/update/:id
  # === PUT   /manifest/update/:id
  # === PATCH /manifest/update/:id
  #
  # @see #update_manifest_path        Route helper
  #
  def update
    __log_activity
    __debug_route
    __debug_request
    @item = update_record
    manifest_authorize!
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

  # === GET /manifest/delete/(:id)
  #
  # Redirects to #delete_select if :id is not given.
  #
  # @see #delete_manifest_path        Route helper
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    @list = delete_records.list&.records
    #manifest_authorize!(@list) # TODO: authorize :delete
  rescue => error
    error_response(error, delete_select_manifest_path)
  end

  # === DELETE /manifest/destroy/:id
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
    @list = destroy_records
    #manifest_authorize!(@list) # TODO: authorize :destroy
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

  # === GET /manifest/list_all
  #
  # List all bulk operation manifests.
  #
  def list_all
    __log_activity
    __debug_route
    list_items
    respond_to do |format|
      format.html { render 'manifest/index' }
      format.json { render 'manifest/index' }
      format.xml  { render 'manifest/index' }
    end
  rescue Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /manifest/list_org
  #
  # List all bulk operation manifests associated with users in the same
  # organization as the current user.
  #
  def list_org
    __log_activity
    __debug_route
    list_items(for_org: true)
    opt = { locals: { name: current_org&.label } }
    respond_to do |format|
      format.html { render 'manifest/index', **opt }
      format.json { render 'manifest/index', **opt }
      format.xml  { render 'manifest/index', **opt }
    end
  rescue Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /manifest/list_own
  #
  # List all bulk operation manifests associated with the current user.
  #
  def list_own
    __log_activity
    __debug_route
    list_items(for_user: true)
    respond_to do |format|
      format.html { render 'manifest/index' }
      format.json { render 'manifest/index' }
      format.xml  { render 'manifest/index' }
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

  # Setup pagination for lists of manifests.
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

  # === GET /manifest/show_select
  #
  # Show a menu to select a manifest to show.
  #
  # @see #show_select_manifest_path   Route helper
  #
  def show_select
    __log_activity
    __debug_route
  end

  # === GET /manifest/edit_select
  #
  # Show a menu to select a manifest to edit.
  #
  # @see #edit_select_manifest_path   Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # === GET /manifest/delete_select
  #
  # Show a menu to select a manifest to delete.
  #
  # @see #delete_select_manifest_path   Route helper
  #
  def delete_select
    __log_activity
    __debug_route
  end

  # === GET /manifest/remit_select
  #
  # Show a menu to select a manifest to submit.
  #
  # @see #remit_select_manifest_path  Route helper
  #
  def remit_select
    __log_activity
    __debug_route
  end

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

  # The minimal set of ManifestItem values returned upon save.
  #
  # Any columns referenced in `manifest.field_error` will also be included.
  #
  # @type [Array<Symbol>]
  #
  # @see file:javascripts/controllers/manifest-edit.js *updateRowValues()*
  #
  ITEM_SAVE_COLS = %i[
    row ready_status last_saved updated_at field_error
  ].freeze

  # === POST  /manifest/save/:id
  # === PUT   /manifest/save/:id
  # === PATCH /manifest/save/:id
  #
  # @see #save_manifest_path                                  Route helper
  # @see file:assets/javascripts/controllers/manifest-edit.js *updateDataRow()*
  #
  def save
    __log_activity
    __debug_route
    @item  = save_changes
    rows   = @item.items_hash(columns: ITEM_SAVE_COLS)
    result = { items: rows }
    render_json result
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === POST  /manifest/cancel/:id
  # === PUT   /manifest/cancel/:id
  # === PATCH /manifest/cancel/:id
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
  # :section: Routes
  # ===========================================================================

  public

  # === GET /manifest/remit/(:id)
  #
  # Redirects to #remit_select if :id is not given.
  #
  # @see #remit_manifest_path         Route helper
  #
  def remit
    __log_activity
    __debug_route
    return redirect_to action: :remit_select if identifier.blank?
    @item = remit_manifest
    manifest_authorize!
  rescue => error
    error_response(error, remit_select_manifest_path)
  end

  # === GET /manifest/get_job_result/:job_id[?column=(output|diagnostic|error)]
  # === GET /manifest/get_job_result/:job_id/*path[?column=(output|diagnostic|error)]
  #
  # Return a value from the 'job_results' table, where :job_id is the value for
  # the matching :active_job_id.
  #
  # @see ApplicationJob::Methods#job_result
  #
  def get_job_result
    render json: SubmitJob.job_result(**normalize_hash(params))
  end

  # ===========================================================================
  # :section: Routes
  # ===========================================================================

  public

=begin # TODO: submission start/stop ?
  # === POST /manifest/start/:id
  #
  # @see #start_manifest_path         Route helper
  #
  def start
    __log_activity
    __debug_route
    @item = start_manifest
    stat  = true # TODO: bulk upload start status
    render json: { id: @item.id, __method__ => stat }
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === POST /manifest/stop/:id
  #
  # @see #stop_manifest_path          Route helper
  #
  def stop
    __log_activity
    __debug_route
    @item = stop_manifest
    stat  = true # TODO: bulk upload abort status
    render json: { id: @item.id, __method__ => stat }
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === POST /manifest/pause/:id
  #
  # @see #pause_manifest_path         Route helper
  #
  def pause
    __log_activity
    __debug_route
    @item = pause_manifest
    stat  = true # TODO: bulk upload pause status
    render json: { id: @item.id, __method__ => stat }
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === POST /manifest/resume/:id
  #
  # @see #resume_manifest_path        Route helper
  #
  def resume
    __log_activity
    __debug_route
    @item = resume_manifest
    stat  = true # TODO: bulk upload resume status
    render json: { id: @item.id, __method__ => stat }
  rescue Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # This is a kludge until I can figure out the right way to express this with
  # CanCan -- or replace CanCan with a more expressive authorization gem.
  #
  # @param [Manifest, Array<Manifest>, nil] subject
  # @param [Symbol, String, nil]            action
  # @param [any, nil]                       args
  #
  def manifest_authorize!(subject = nil, action = nil, *args)
    action  ||= request_parameters[:action]
    action    = action.to_sym if action.is_a?(String)
    subject ||= @item
    subject   = subject.first if subject.is_a?(Array) # TODO: per item check
    # noinspection RubyMismatchedArgumentType
    authorize!(action, subject, *args) if subject
    return if administrator?
    return unless %i[show edit update delete destroy].include?(action)
    unless (org = current_org&.id) && (subject&.org&.id == org)
      message = current_ability.unauthorized_message(action, subject)
      message.sub!(/s\.?$/, " #{subject.id}") if subject
      raise CanCan::AccessDenied.new(message, action, subject, args)
    end
  end

end

__loading_end(__FILE__)
