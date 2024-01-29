# app/controllers/upload_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Handle "/upload" requests.
#
# @see UploadDecorator
# @see UploadsDecorator
# @see file:app/views/upload/**
#
#--
# noinspection RubyTooManyMethodsInspection
#++
class UploadController < ApplicationController

  include UserConcern
  include ParamsConcern
  include OptionsConcern
  include SessionConcern
  include RunStateConcern
  include PaginationConcern
  include ApiConcern
  include AwsConcern
  include IngestConcern
  include IaDownloadConcern
  include UploadConcern

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

  ADMIN_ROUTES = %i[api_migrate bulk_reindex].freeze
  ANON_ROUTES  = %i[show records].freeze

  before_action :update_user
  before_action :authenticate_admin!, only:   ADMIN_ROUTES
  before_action :authenticate_user!,  except: ADMIN_ROUTES + ANON_ROUTES

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check only: ANON_ROUTES

  authorize_resource instance_name: :item

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  OPS      = %i[new edit delete].freeze
  BULK_OPS = %i[bulk_new bulk_edit bulk_delete].freeze
  ALL_OPS  = [*OPS, *BULK_OPS, :bulk_reindex].freeze
  MENUS    = %i[show_select edit_select delete_select].freeze

  before_action :set_ingest_engine, only: [:index, :bulk_index, *ALL_OPS]
  before_action :index_redirect,    only: :show
  before_action :save_search_menus, only: :admin

  # ===========================================================================
  # :section:
  # ===========================================================================

  respond_to :html
  respond_to :json, :xml, except: ALL_OPS + MENUS

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Results for :index.
  #
  # @return [Array<Upload,String>]
  # @return [Hash{Symbol=>*}]
  # @return [nil]
  #
  attr_reader :list

  # API results for :show.
  #
  # @return [Upload, nil]
  #
  attr_reader :item

  # For the :admin endpoint.
  #
  # @return [Hash{String=>Array<Aws::S3::Object>}]
  #
  attr_reader :s3_object_table
  helper_attr :s3_object_table

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /upload[?id=(:id|SID|RANGE_LIST)]
  # === GET /upload[?selected=(:id|SID|RANGE_LIST)]
  # === GET /upload[?group=WORKFLOW_GROUP]
  #
  # List submissions and entries.
  #
  # If an item specification is given by one of Upload::Options#identifier_keys
  # then the results will be limited to the matching upload(s).
  # NOTE: Currently this is not limited only to the current user's uploads.
  #
  # @see #upload_index_path           Route helper
  #
  def index
    __log_activity
    __debug_route
    prm = paginator.initial_parameters
    if prm.except(:sort, *Paginator::NON_SEARCH_KEYS).present?
      # Apply parameters to render a page of items.
      list_items(prm)
      respond_to do |format|
        format.html
        format.json { render_json index_values }
        format.xml  { render_xml  index_values(item: :entry) }
      end
    else
      # If not performing a search, redirect to the appropriate view action.
      prm[:action] = :list_own
      respond_to do |format|
        format.html { redirect_to prm }
        format.json { redirect_to prm.merge!(format: :json) }
        format.xml  { redirect_to prm.merge!(format: :xml) }
      end
    end
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /upload/show/(:id|SID)
  #
  # Display a single upload.
  #
  # Redirects to #show_select if :id is missing.
  #
  # @see #show_upload_path            Route helper
  #
  def show
    __log_activity(anonymous: true)
    __debug_route
    return redirect_to action: :show_select if identifier.blank?
    @item = find_record
    upload_authorize!
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue UploadWorkflow::SubmitError, Record::SubmitError,
    ActiveRecord::RecordNotFound, Record::NotFound => error
    # As a convenience (for HTML only), if an index item is actually on another
    # instance, fetch it from there to avoid a potentially confusing result.
    if request.format.html?
      # noinspection RubyMismatchedArgumentType
      [PRODUCTION_BASE_URL, STAGING_BASE_URL].find do |base_url|
        next if base_url.start_with?(request.base_url)
        @host = base_url
        @item = proxy_get_record(identifier, @host)
      end
    end
    error_response(error) if @item.blank?
  rescue => error
    error_response(error)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # === GET /upload/new
  #
  # Initiate creation of a new EMMA entry by prompting to upload a file.
  #
  # On the initial visit to the page, #db_id should be *nil*.  On subsequent
  # visits (due to "Cancel" returning to this same page), #db_id will be
  # included in order to reuse the Upload record that was created at that time.
  #
  # @see #new_upload_path             Route helper
  # @see UploadController#create
  # @see UploadWorkflow::Single::Create::States#on_creating_entry
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def new
    __log_activity
    __debug_route
    @item = wf_single(rec: (db_id || :unset), event: :create)
    upload_authorize!
  rescue => error
    failure_status(error)
  end

  # === POST  /upload/create
  # === PUT   /upload/create
  # === PATCH /upload/create
  #
  # Invoked from the handler for the Uppy 'upload-success' event to finalize
  # the creation of a new EMMA entry.
  #
  # @see #create_upload_path          Route helper
  # @see UploadController#new
  # @see UploadWorkflow::Single::Create::States#on_submitting_entry
  #
  def create
    __log_activity
    __debug_route
    @item = wf_single(event: :submit)
    upload_authorize!
    post_response(:ok, @item, redirect: upload_index_path)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /upload/edit/(:id)
  #
  # Initiate modification of an existing EMMA entry by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  # Redirects to #edit_select if :id is missing.
  #
  # @see #edit_upload_path            Route helper
  # @see UploadController#update
  # @see UploadWorkflow::Single::Edit::States#on_editing_entry
  #
  def edit
    __log_activity
    __debug_route
    return redirect_to action: :edit_select if identifier.blank?
    @item = wf_single(event: :edit)
    upload_authorize!
  rescue => error
    error_response(error)
  end

  # === PUT   /upload/update/:id
  # === PATCH /upload/update/:id
  #
  # Finalize modification of an existing EMMA entry.
  #
  # @see #update_upload_path          Route helper
  # @see UploadController#edit
  # @see UploadWorkflow::Single::Edit::States#on_modifying_entry
  #
  def update
    __log_activity
    __debug_route
    __debug_request
    @item = wf_single(event: :submit)
    upload_authorize!
    post_response(:ok, @item, redirect: upload_index_path)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # === GET /upload/delete/:id[?force=true&truncate=true&emergency=true]
  # === GET /upload/delete/SID[?...]
  # === GET /upload/delete/RANGE_LIST[?...]
  #
  # Initiate removal of an existing EMMA entry along with its associated file.
  #
  # Redirects to #delete_select if :id is missing.
  #
  # Use :force to attempt to remove an item from the EMMA Unified Index even if
  # a database record was not found.
  #
  # @see #delete_upload_path          Route helper
  # @see UploadWorkflow::Single::Remove::States#on_removing_entry
  # @see UploadController#destroy
  #
  def delete
    __log_activity
    __debug_route
    return redirect_to action: :delete_select if identifier.blank?
    @list = wf_single(rec: :unset, data: identifier, event: :remove)
    #upload_authorize!(@list) # TODO: authorize :delete
  rescue => error
    error_response(error)
  end

  # === DELETE /upload/destroy/:id[?force=true&truncate=true&emergency=true]
  # === DELETE /upload/destroy/SID[?...]
  # === DELETE /upload/destroy/RANGE_LIST[?...]
  #
  # Finalize removal of an existing EMMA entry.
  #
  # @see #destroy_upload_path         Route helper
  # @see UploadWorkflow::Single::Remove::States#on_removed_entry
  # @see UploadController#delete
  #
  #--
  # noinspection RubyScope
  #++
  def destroy
    __log_activity
    __debug_route
    back  = delete_select_upload_path
    rec   = :unset
    dat   = identifier
    opt   = { start_state: :removing, event: :submit, variant: :remove }
    @list = wf_single(rec: rec, data: dat, **opt)
    raise_failure(:file_id) unless @list.present?
    #upload_authorize!(@list) # TODO: authorize :destroy
    post_response(:ok, @list, redirect: back)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error, redirect: back)
  rescue => error
    post_response(:not_found, error, redirect: back)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /upload/list_all
  #
  # List all submissions and entries.
  #
  def list_all
    __log_activity
    __debug_route
    list_items
    respond_to do |format|
      format.html { render 'upload/index' }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :entry) }
    end
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /upload/list_org
  #
  # List all submissions and entries associated with users in the same
  # organization as the current user.
  #
  def list_org
    __log_activity
    __debug_route
    list_items(for_org: true)
    opt = { locals: { name: current_org&.label } }
    respond_to do |format|
      format.html { render 'upload/index', **opt }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :entry) }
    end
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # === GET /upload/list_own
  #
  # List all submissions and entries associated with the current user.
  #
  def list_own
    __log_activity
    __debug_route
    list_items(for_user: true)
    respond_to do |format|
      format.html { render 'upload/index' }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :entry) }
    end
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Setup pagination for lists of Upload items.
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
    all   = prm[:group].nil? || (prm[:group].to_sym == :all)
    items = find_or_match_records(groups: all, **prm)
    paginator.finalize(items, **prm)
    items = find_or_match_records(groups: :only, **prm) if prm.delete(:group)
    @group_counts = items[:groups]
    # noinspection RubyMismatchedReturnType
    prm
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /upload/show_select
  #
  # Show a menu to select an EMMA entry to show.
  #
  # @see #show_select_upload_path     Route helper
  #
  def show_select
    __log_activity
    __debug_route
  end

  # === GET /upload/edit_select
  #
  # Show a menu to select an EMMA entry to edit.
  #
  # @see #edit_select_upload_path     Route helper
  #
  def edit_select
    __log_activity
    __debug_route
  end

  # === GET /upload/delete_select
  #
  # Show a menu to select an EMMA entry to delete.
  #
  # @see #delete_select_upload_path   Route helper
  #
  def delete_select
    __log_activity
    __debug_route
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # === GET /upload/bulk
  #
  # Currently a non-functional placeholder.
  #
  # @see #bulk_upload_index_path      Route helper
  #
  def bulk_index
    __log_activity
    __debug_route
  rescue => error
    failure_status(error, status: :bad_request)
  end

  # === GET /upload/bulk_new[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Display a form prompting for a bulk operation manifest (either CSV or JSON)
  # containing an row/element for each entry to submit.
  #
  # @see #bulk_new_upload_path        Route helper
  # @see UploadWorkflow::Bulk::Create::States#on_creating_entry
  # @see UploadController#bulk_create
  #
  def bulk_new
    __log_activity
    __debug_route
    wf_bulk(rec: :unset, data: :unset, event: :create)
  rescue => error
    failure_status(error)
  end

  # === POST /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Create the specified Upload records, download and store the associated
  # files, and post the new entries to the EMMA Unified Ingest API.
  #
  # @see #bulk_create_upload_path     Route helper
  # @see UploadWorkflow::Bulk::Create::States#on_submitting_entry
  # @see UploadController#bulk_new
  #
  def bulk_create
    __log_activity
    __debug_route
    __debug_request
    @list = wf_bulk(start_state: :creating, event: :submit, variant: :create)
    wf_check_partial_failure
    post_response(:ok, @list, xhr: false)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error, xhr: false)
  rescue => error
    post_response(error, xhr: false)
  end

  # === GET /upload/bulk_edit[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Display a form prompting for a bulk operation manifest (either CSV or JSON)
  # containing an row/element for each entry to change.
  #
  # @see #bulk_edit_upload_path       Route helper
  # @see UploadWorkflow::Bulk::Edit::States#on_editing_entry
  # @see UploadController#bulk_update
  #
  def bulk_edit
    __log_activity
    __debug_route
    @list = wf_bulk(rec: :unset, data: :unset, event: :edit)
  rescue => error
    failure_status(error)
  end

  # === PUT   /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  # === PATCH /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Modify or create the specified Upload records, download and store the
  # associated files (if changed), and post the new/modified entries to the
  # EMMA Unified Ingest API.
  #
  # @see #bulk_update_upload_path     Route helper
  # @see UploadWorkflow::Bulk::Edit::States#on_modifying_entry
  # @see UploadController#bulk_edit
  #
  def bulk_update
    __log_activity
    __debug_route
    __debug_request
    @list = wf_bulk(start_state: :editing, event: :submit, variant: :edit)
    wf_check_partial_failure
    post_response(:ok, @list, xhr: false)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error, xhr: false)
  rescue => error
    post_response(error, xhr: false)
  end

  # === GET /upload/bulk_delete[?force=false]
  #
  # Specify entries to delete by :id, SID, or RANGE_LIST.
  #
  # @see #bulk_delete_upload_path     Route helper
  # @see UploadWorkflow::Bulk::Remove::States#on_removing_entry
  # @see UploadController#bulk_destroy
  #
  def bulk_delete
    __log_activity
    __debug_route
    @list = wf_bulk(event: :remove)
  rescue => error
    failure_status(error)
  end

  # === DELETE /upload/bulk[?force=true]
  #
  # @see #bulk_destroy_upload_path    Route helper
  # @see UploadWorkflow::Bulk::Remove::States#on_removed_entry
  # @see UploadController#bulk_delete
  #
  def bulk_destroy
    __log_activity
    __debug_route
    __debug_request
    @list = wf_bulk(start_state: :removing, event: :submit, variant: :remove)
    raise_failure(:file_id) unless @list.present?
    wf_check_partial_failure
    post_response(:ok, @list)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error, xhr: false)
  rescue => error
    post_response(error, xhr: false)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # === POST /upload/renew
  #
  # Invoked to re-create a database entry that had been canceled.
  #
  # @see #renew_upload_path                                 Route helper
  # @see file:app/assets/javascripts/feature/model-form.js  *refreshRecord()*
  #
  def renew
    __log_activity
    __debug_route
    @item = wf_single(rec: :unset, event: :create)
    upload_authorize!
    respond_to do |format|
      format.html
      format.json { render json: @item }
      format.xml  { render xml:  @item }
    end
  rescue => error
    post_response(error)
  end

  # === POST /upload/reedit?id=:id
  #
  # Invoked to re-start editing a database entry.
  #
  # @see #reedit_upload_path                                Route helper
  # @see file:app/assets/javascripts/feature/model-form.js  *refreshRecord()*
  #
  def reedit
    __log_activity
    __debug_route
    @item = wf_single(event: :edit)
    upload_authorize!
    respond_to do |format|
      format.html
      format.json { render json: @item }
      format.xml  { render xml:  @item }
    end
  rescue => error
    post_response(error)
  end

  # === GET  /upload/cancel?id=:id[&redirect=URL][&reset=bool][&fields=...]
  # === POST /upload/cancel?id=:id[&fields=...]
  #
  # Invoked to cancel the current submission form instead of submitting.
  #
  # * If invoked via :get, a :redirect is expected.
  # * If invoked via :post, only a status is returned.
  #
  # Either way, the identified Upload record is deleted if it was in the
  # :create phase.  If it was in the :edit phase, its fields are reset
  #
  # @see #cancel_upload_path                                Route helper
  # @see UploadWorkflow::Single::States#on_canceled_entry
  # @see UploadWorkflow::Bulk::States#on_canceled_entry
  # @see file:app/assets/javascripts/feature/model-form.js  *cancelForm()*
  #
  def cancel
    __log_activity
    __debug_route
    @item = wf_single(event: :cancel)
    if request.get?
      # noinspection RubyMismatchedArgumentType
      redirect_to(params[:redirect] || upload_index_path)
    else
      post_response(:ok)
    end
  rescue => error
    if request.get?
      failure_status(error)
    else
      post_response(error)
    end
  end

  # === GET /upload/check/:id
  # === GET /upload/check/SID
  #
  # Invoked to determine whether the workflow state of the indicated item can
  # be advanced.
  #
  # @see #check_upload_path           Route helper
  # @see UploadConcern#wf_single_check
  #
  def check
    __log_activity
    __debug_route
    @list = wf_single_check
    data  = { messages: @list }
    respond_to do |format|
      format.html
      format.json { render_json data }
      format.xml  { render_xml  data }
    end
  rescue => error
    failure_status(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === POST /upload/upload
  #
  # Invoked from 'Uppy.XHRUpload'.
  #
  # @see #upload_upload_path          Route helper
  # @see UploadWorkflow::Single::Create::States#on_validating_entry
  # @see UploadWorkflow::Single::Edit::States#on_replacing_entry
  # @see UploadWorkflow::External#upload_file
  # @see file:app/assets/javascripts/feature/model-form.js
  #
  def upload
    __log_activity
    __debug_route
    __debug_request
    rec = db_id || identifier
    dat = { env: request.env }
    stat, hdrs, body = wf_single(rec: rec, data: dat, event: :upload)
    self.status = stat        if stat.present?
    self.headers.merge!(hdrs) if hdrs.present?
    self.response_body = body if body.present?
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error, xhr: true)
  rescue => error
    post_response(error, xhr: true)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /download/:id
  #
  # Download the file associated with an EMMA submission.
  #
  # @see #file_download_path          Route helper
  # @see Upload#download_url
  #
  def download
    __log_activity
    __debug_route
    @item = find_record
    link  = @item.download_url
    respond_to do |format|
      format.html { redirect_to(link, allow_other_host: true) }
      format.json { render_json download_values(link) }
      format.xml  { render_xml  download_values(link) }
    end
  rescue => error
    post_response(error, xhr: true)
  end

  # === GET /retrieval?url=URL
  #
  # Retrieve a file from a partner repository that supports proxying through
  # the EMMA server.
  #
  # @raise [ExecError] @see IaDownloadConcern#ia_download_response
  #
  # @see #retrieval_path              Route helper
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def retrieval
    __log_activity
    __debug_route
    url = params[:url]
    if !ia_link?(url)
      Log.error { "/retrieval can't handle #{url.inspect}" }
    elsif IA_DIRECT_LINK_PATTERNS.any? { |pattern| url.match?(pattern) }
      return redirect_to url
    else
      # noinspection xRubyUnnecessaryReturnStatement
      ia_download_response(url)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /upload/admin[?(deploy|deployment)=('production'|'staging')]
  # === GET /upload/admin[?(repo|repository)=('emma'|'ia')]
  #
  # Upload submission administration.
  #
  # @see #admin_upload_path           Route helper
  # @see AwsConcern#get_object_table
  #
  def admin
    __log_activity
    __debug_route
    @s3_object_table = get_s3_object_table(**url_parameters)
  rescue => error
    failure_status(error)
  end

  # === GET /upload/records[?start_date=DATE&end_date=DATE]
  #
  # Generate record information for APTrust backup.
  #
  # Unless "logging=true" is given in the URL parameters, log output is
  # suppressed within the method.
  #
  def records
    __log_activity
    __debug_route
    prm  = current_params
    opt  = { repository: EmmaRepository.default, state: :completed }.merge(prm)
    log  = true?(opt.delete(:logging))
    recs = ->(*) { Upload.get_relation(**opt).map { |rec| record_value(rec) } }
    @list = log ? recs.() : Log.silence(&recs)
    respond_to do |format|
      format.html { redirect_to prm.merge!(format: :json) }
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :entry) }
    end
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    error_response(error)
  rescue => error
    error_response(error, root_path)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # === GET /upload/api_migrate?(v|version)=[0.0.]5(&verbose=true&dryrun=false)
  #
  # Modify :emma_data fields and content.
  #
  # @see #api_migrate_path            Route helper
  # @see ApiConcern#api_data_migration
  #
  def api_migrate
    __log_activity
    __debug_route
    @list = api_data_migration(**request_parameters)
    respond_to do |format|
      format.html
      format.json { render json: @list }
      format.xml  { render xml:  @list }
    end
  rescue => error
    failure_status(error)
  end

  # === GET /upload/bulk_reindex?size=PAGE_SIZE[&id=(:id|SID|RANGE_LIST)]
  #
  # Cause completed submission records to be re-indexed.
  #
  # @see #bulk_reindex_upload_path    Route helper
  #
  def bulk_reindex
    __log_activity
    __debug_route
    prm = request_parameters.slice(:size).merge!(meth: __method__)
    @list, failed = reindex_submissions(*identifier, **prm)
    raise_failure(:invalid, failed.uniq) if failed.present?
  rescue => error
    failure_status(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A record representation including URL of the remediated content file.
  #
  # @param [Upload] rec
  #
  # @return [Hash]
  #
  def record_value(rec)
    {
      submission_id: rec.submission_id,
      created_at:    rec.created_at,
      updated_at:    rec.updated_at,
      user_id:       rec.uid,
      user:          User.account_name(rec),
      file_url:      get_s3_public_url(rec),
      file_data:     safe_json_parse(rec.file_data),
      emma_data:     rec.emma_metadata,
    }
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # If the :show endpoint is given an :id which is actually a specification for
  # multiple items then there is a redirect to :index.
  #
  # @return [void]
  #
  def index_redirect
    return unless identifier&.to_s&.match?(/[^[:alnum:]]/)
    redirect_to action: :index, selected: identifier
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Response values for de-serializing download information to JSON or XML.
  #
  # @param [String,nil] url
  #
  # @return [Hash{Symbol=>String,nil}]
  #
  def download_values(url)
    { url: url }
  end

  # This is a kludge until I can figure out the right way to express this with
  # CanCan -- or replace CanCan with a more expressive authorization gem.
  #
  # @param [Upload, Array<Upload>, nil] subject
  # @param [Symbol, String, nil]        action
  # @param [*]                          args
  #
  def upload_authorize!(subject = nil, action = nil, *args)
    action  ||= request_parameters[:action]
    action    = action.to_sym if action.is_a?(String)
    subject ||= @item
    subject   = subject.first if subject.is_a?(Array) # TODO: per item check
    # noinspection RubyMismatchedArgumentType
    authorize!(action, subject, *args) if subject
    return if administrator?
    return unless %i[edit update delete destroy].include?(action)
    unless (org = current_org&.id) && (subject&.org&.id == org)
      message = current_ability.unauthorized_message(action, subject)
      message.sub!(/s\.?$/, " #{subject.id}") if subject
      raise CanCan::AccessDenied.new(message, action, subject, args)
    end
  end

end

__loading_end(__FILE__)
