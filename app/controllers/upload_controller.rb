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
  include SerializationConcern
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

  ADMIN_ROUTES = %i[api_migrate bulk_reindex]
  ANON_ROUTES  = %i[show records]

  before_action :update_user
  before_action :authenticate_admin!, only:   ADMIN_ROUTES
  before_action :authenticate_user!,  except: (ADMIN_ROUTES + ANON_ROUTES)

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  skip_authorization_check only: ANON_ROUTES

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_ingest_engine, only: %i[
    index         new           edit          delete
    bulk_index    bulk_new      bulk_edit     bulk_delete   bulk_reindex
  ]
  before_action :index_redirect,        only: %i[show]
  before_action :set_item_download_url, only: %i[retrieval]
  before_action :resolve_sort,          only: %i[admin]

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

  # == GET /upload[?id=(:id|SID|RANGE_LIST)]
  # == GET /upload[?selected=(:id|SID|RANGE_LIST)]
  # == GET /upload[?group=WORKFLOW_GROUP]
  #
  # Display the current user's uploads.
  #
  # If an item specification is given by one of UploadConcern#IDENTIFIER_PARAMS
  # then the results will be limited to the matching upload(s).
  # NOTE: Currently this is not limited only to the current user's uploads.
  #
  # @see #upload_index_path           Route helper
  # @see UploadConcern#find_or_match_records
  #
  def index
    __log_activity
    __debug_route
    prm    = paginator.initial_parameters
    all    = prm[:group].nil? || (prm[:group].to_sym == :all)
    result = find_or_match_records(groups: all, **prm)
    @list  = paginator.finalize(result, **prm)
    result = find_or_match_records(groups: :only, **prm) if prm.delete(:group)
    @group_counts = result[:groups]
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values(item: :entry) }
    end
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    show_search_failure(error)
  rescue => error
    show_search_failure(error, root_path)
  end

  # == GET /upload/show/(:id|SID)
  #
  # Display a single upload.
  #
  # @see #show_upload_path            Route helper
  # @see UploadConcern#get_record
  #
  def show
    __log_activity(anonymous: true)
    __debug_route
    @item = get_record
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue UploadWorkflow::SubmitError, Record::NotFound,
    ActiveRecord::RecordNotFound => error
    # As a convenience (for HTML only), if an index item is actually on another
    # instance, fetch it from there to avoid a potentially confusing result.
    if request.format.html?
      # noinspection RubyMismatchedArgumentType
      [STAGING_BASE_URL, PRODUCTION_BASE_URL].find do |base_url|
        next if base_url.start_with?(request.base_url)
        @host = base_url
        @item = proxy_get_record(identifier, @host)
      end
    end
    show_search_failure(error) if @item.blank?
  rescue => error
    show_search_failure(error)
  end

  # ===========================================================================
  # :section: Workflow - Single
  # ===========================================================================

  public

  # == GET /upload/new
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
  rescue => error
    failure_status(error)
  end

  # == POST  /upload/create
  # == PUT   /upload/create
  # == PATCH /upload/create
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
    post_response(:ok, @item, redirect: upload_index_path)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # == GET /upload/edit/:id
  # == GET /upload/edit/SELECT
  # == GET /upload/edit_select
  #
  # Initiate modification of an existing EMMA entry by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  # If :id is "SELECT" then a menu of editable items is presented.
  #
  # @see #edit_upload_path            Route helper
  # @see #edit_select_upload_path     Route helper
  # @see UploadController#update
  # @see UploadWorkflow::Single::Edit::States#on_editing_entry
  #
  def edit
    __log_activity
    __debug_route
    @item = (wf_single(event: :edit) unless show_menu?)
  rescue => error
    failure_status(error)
  end

  # == PUT   /upload/update/:id
  # == PATCH /upload/update/:id
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
    post_response(:ok, @item, redirect: upload_index_path)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # == GET /upload/delete/:id[?force=true&truncate=true&emergency=true]
  # == GET /upload/delete/SID[?...]
  # == GET /upload/delete/RANGE_LIST[?...]
  # == GET /upload/delete/SELECT[?...]
  # == GET /upload/delete_select
  #
  # Initiate removal of an existing EMMA entry along with its associated file.
  #
  # If :id is "SELECT" then a menu of deletable items is presented.
  #
  # Use :force to attempt to remove an item from the EMMA Unified Index even if
  # a database record was not found.
  #
  # @see #delete_upload_path          Route helper
  # @see #delete_select_upload_path   Route helper
  # @see UploadWorkflow::Single::Remove::States#on_removing_entry
  # @see UploadController#destroy
  #
  def delete
    __log_activity
    __debug_route
    @list = []
    unless show_menu?
      @list = wf_single(rec: :unset, data: identifier, event: :remove)
    end
  rescue => error
    failure_status(error)
  end

  # == DELETE /upload/destroy/:id[?force=true&truncate=true&emergency=true]
  # == DELETE /upload/destroy/SID[?...]
  # == DELETE /upload/destroy/RANGE_LIST[?...]
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
    failure(:file_id) unless @list.present?
    post_response(:ok, @list, redirect: back)
  rescue UploadWorkflow::SubmitError, Record::SubmitError => error
    post_response(:conflict, error, redirect: back)
  rescue => error
    post_response(:not_found, error, redirect: back)
  end

  # ===========================================================================
  # :section: Workflow - Bulk
  # ===========================================================================

  public

  # == GET /upload/bulk
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

  # == GET /upload/bulk_new[?source=FILE&batch=true|SIZE&prefix=STRING]
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

  # == POST /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
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

  # == GET /upload/bulk_edit[?source=FILE&batch=true|SIZE&prefix=STRING]
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

  # == PUT   /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  # == PATCH /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
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

  # == GET /upload/bulk_delete[?force=false]
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

  # == DELETE /upload/bulk[?force=true]
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
    failure(:file_id) unless @list.present?
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

  # == POST /upload/renew
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
    respond_to do |format|
      format.html
      format.json { render json: @item }
      format.xml  { render xml:  @item }
    end
  rescue => error
    post_response(error)
  end

  # == POST /upload/reedit?id=:id
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
    respond_to do |format|
      format.html
      format.json { render json: @item }
      format.xml  { render xml:  @item }
    end
  rescue => error
    post_response(error)
  end

  # == GET  /upload/cancel?id=:id[&redirect=URL][&reset=bool][&fields=...]
  # == POST /upload/cancel?id=:id[&fields=...]
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

  # == GET /upload/check/:id
  # == GET /upload/check/SID
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

  # == POST /upload/upload
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

  # == GET /download/:id
  #
  # Download the file associated with an EMMA submission.
  #
  # @see #file_download_path          Route helper
  # @see UploadConcern#get_record
  # @see Upload#download_url
  #
  def download
    __log_activity
    __debug_route
    @item = get_record
    link  = @item.download_url
    respond_to do |format|
      format.html { redirect_to(link, allow_other_host: true) }
      format.json { render_json download_values(link) }
      format.xml  { render_xml  download_values(link) }
    end
  rescue => error
    post_response(error, xhr: true)
  end

  # == GET /retrieval?url=URL
  #
  # Retrieve a file from a member repository that supports proxying through the
  # EMMA server.
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
    if ia_link?(item_download_url)
      ia_download_response(item_download_url)
    else
      Log.error { "/retrieval can't handle #{item_download_url.inspect}" }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /upload/admin[?(deploy|deployment)=('production'|'staging')]
  # == GET /upload/admin[?(repo|repository)=('emma'|'ia')]
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

  # == GET /upload/records[?start_date=DATE&end_date=DATE]
  #
  # Generate record information for APTrust backup.
  #
  # Unless "logging=true" is given in the URL parameters, log output is
  # suppressed within the method.
  #
  def records
    __log_activity
    __debug_route
    prm  = upload_params
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
    show_search_failure(error)
  rescue => error
    show_search_failure(error, root_path)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /upload/api_migrate?(v|version)=[0.0.]5(&verbose=true&dryrun=false)
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

  # == GET /upload/bulk_reindex?size=PAGE_SIZE[&id=(:id|SID|RANGE_LIST)]
  #
  # Cause completed submission records to be re-indexed.
  #
  # @see #bulk_reindex_upload_path    Route helper
  # @see UploadConcern#reindex_record
  #
  def bulk_reindex
    __log_activity
    __debug_route
    prm = request_parameters.slice(:size).merge!(meth: __method__)
    @list, failed = reindex_submissions(*identifier, **prm)
    failure(:invalid, failed.uniq) if failed.present?
  rescue => error
    failure_status(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether URL parameters require that a menu should be shown rather
  # than operating on an explicit set of identifiers.
  #
  # @param [String, Array, nil] id_params  Default: `UploadConcern#identifier`.
  #
  def show_menu?(id_params = nil)
    Array.wrap(id_params || identifier).include?('SELECT')
  end

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # @param [Exception] error
  # @param [String]    fallback   Redirect fallback (def.: #upload_index_path).
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
      redirect_back(fallback_location: (fallback || upload_index_path))
    end
  end

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
      user_id:       rec.user_id,
      user:          User.uid_value(rec.user_id),
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
    return unless identifier&.match?(/[^[:alnum:]]/)
    redirect_to action: :index, selected: identifier
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [*]    list
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list, **opt)
    opt.reverse_merge!(wrap: :entries)
    super(list, **opt)
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Upload, Hash] item
  # @param [Hash]         opt
  #
  # @return [Hash{Symbol=>*}]
  #
  def show_values(item = @item, **opt)
    item = item.try(:fields) || item.dup
    data = item.extract!(:file_data).first&.last
    item[:file_data] = safe_json_parse(data)
    super(item, **opt)
  end

  # Response values for de-serializing download information to JSON or XML.
  #
  # @param [String,nil] url
  #
  # @return [Hash{Symbol=>String,nil}]
  #
  def download_values(url)
    { url: url }
  end

end

__loading_end(__FILE__)
