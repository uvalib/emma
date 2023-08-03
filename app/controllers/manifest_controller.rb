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
  # :section:
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, except: %i[edit]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

  # === GET /manifest
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
    return redirect_to prm.merge!(action: :edit) if identifier.present?
    sort   = prm.delete(:sort) || { updated_at: :desc }
    result = find_or_match_records(sort: sort, **prm)
    @list  = paginator.finalize(result, **prm)
    respond_to do |format|
      format.html
      format.json #{ render_json index_values }
      format.xml  #{ render_xml  index_values }
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
    @item = get_record
    manifest_authorize!(__method__, @item)
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
    manifest_authorize!(__method__, @item)
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
    manifest_authorize!(__method__, @item)
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
    @item  = edit_record
    manifest_authorize!(__method__, @item)
    prm    = paginator.initial_parameters
    result = find_or_match_manifest_items(@item, **prm)
    paginator.finalize(result, **prm)
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
    manifest_authorize!(__method__, @item)
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
    @list = delete_records[:list]
    #manifest_authorize!(__method__, @list) # TODO: authorize :delete
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
    #manifest_authorize!(__method__, @list) # TODO: authorize :destroy
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
  # :section:
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
  # :section:
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
    manifest_authorize!(__method__, @item)
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
  # :section:
  # ===========================================================================

  public

=begin
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
  # @param [Symbol]                         action
  # @param [Manifest, Array<Manifest>, nil] subject
  # @param [*]                              args
  #
  def manifest_authorize!(action, subject, *args)
    subject = subject.first if subject.is_a?(Array) # TODO: per item check
    subject = subject.presence
    authorize!(action, subject, *args) if subject
    return if administrator?
    return unless %i[show edit update delete destroy].include?(action)
    unless (org = current_user&.org&.id) && (subject&.org&.id == org)
      message = current_ability.unauthorized_message(action, subject)
      message.sub!(/s\.?$/, " #{subject.id}") if subject
      raise CanCan::AccessDenied.new(message, action, subject, args)
    end
  end

end

__loading_end(__FILE__)
