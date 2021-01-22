# app/controllers/upload_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# UploadController
#
class UploadController < ApplicationController

  include UserConcern
  include ParamsConcern
  include SessionConcern
  include PaginationConcern
  include SerializationConcern
  include AwsConcern
  include UploadConcern
  include IaDownloadConcern

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  include AbstractController::Callbacks unless ONLY_FOR_DOCUMENTATION
  # :nocov:

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  before_action :update_user
  before_action :authenticate_user!, except: %i[show]

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  authorize_resource

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  before_action :set_identifiers, only: %i[index    show
                                           create
                                           edit     update
                                           delete   destroy
                                           cancel   check
                                           endpoint download]
  before_action :index_redirect,  only: %i[show]
  before_action :set_url,         only: %i[retrieval]
  before_action :set_member,      only: %i[retrieval]
  before_action :resolve_sort,    only: %i[admin]

  respond_to :html
  respond_to :json, :xml, except: %i[edit]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /upload[?id={:id|SID|RANGE_LIST}]
  # == GET /upload[?selected={:id|SID|RANGE_LIST}]
  # == GET /upload[?group=WORKFLOW_GROUP]
  #
  # Display the current user's uploads.
  #
  # If an item specification is given by one of UploadConcern#IDENTIFIER_PARAMS
  # then the results will be limited to the matching upload(s).
  # NOTE: Currently this is not limited only to the current user's uploads.
  #
  # @see UploadConcern#find_or_match_records
  #
  def index
    __debug_route
    opt    = url_parameters.except!(*FORM_PARAMS)
    all    = opt[:group].nil? || (opt[:group].to_sym == :all)
    result = find_or_match_records(groups: all, **opt)
    first, last, page, @list = result.values_at(:first, :last, :page, :list)
    self.page_items  = @list
    self.page_size   = result[:limit]
    self.page_offset = result[:offset]
    self.total_items = result[:total]
    self.next_page   = (url_for(opt.merge(page: (page + 1))) unless last)
    self.prev_page   = (url_for(opt.merge(page: (page - 1))) unless first)
    self.first_page  = (url_for(opt.except(*PAGE_PARAMS))    unless first)
    self.prev_page   = first_page if page == 2
    result = find_or_match_records(groups: :only, **opt) if opt.delete(:group)
    @group_counts    = result[:groups]
    respond_to do |format|
      format.html
      format.json { render_json index_values }
      format.xml  { render_xml  index_values }
    end
  rescue SubmitError => error
    show_search_failure(error, upload_index_path)
  rescue => error
    show_search_failure(error, root_path)
  end

  # == GET /upload/show/{:id|SID}
  #
  # Display a single upload.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  #
  # @see UploadConcern#get_record
  #
  def show
    __debug_route
    @item = get_record(@identifier)
    respond_to do |format|
      format.html
      format.json { render_json show_values }
      format.xml  { render_xml  show_values }
    end
  rescue SubmitError => error
    # As a convenience, if an index item is actually on another instance, fetch
    # it from there to avoid a potentially confusing result.
    [STAGING_BASE_URL, PRODUCTION_BASE_URL].find do |base_url|
      next if base_url.start_with?(request.base_url)
      @host = base_url
      @item = proxy_get_record(@identifier, @host)
    end
    show_search_failure(error, upload_index_path) if @item.blank?
  rescue => error
    show_search_failure(error, upload_index_path)
  end

  # == GET /upload/new
  #
  # Initiate creation of a new EMMA entry by prompting to upload a file.
  #
  # On the initial visit to the page, @db_id should be *nil*.  On subsequent
  # visits (due to "Cancel" returning to this same page), @db_id will be
  # included in order to reuse the the Upload record that was created at that
  # time.
  #
  # @see UploadController#create
  # @see UploadWorkflow::Single::Create::States#on_creating_entry
  # @see app/assets/javascripts/feature/file-upload.js
  #
  def new
    __debug_route
    @item = wf_single(rec: (@db_id || :unset), event: :create)
  rescue => error
    flash_now_failure(error)
  end

  # == POST /upload
  #
  # Invoked from the handler for the Uppy 'upload-success' event to finalize
  # the creation of a new EMMA entry.
  #
  # @raise [Net::HTTPConflict]
  # @raise [UploadWorkflow::SubmitError]
  #
  # @see UploadWorkflow::Single::Create::States#on_submitting_entry
  # @see app/assets/javascripts/feature/file-upload.js
  #
  def create
    __debug_route
    @item = wf_single(event: :submit)
    post_response(:ok, @item, redirect: upload_index_path)
  rescue SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # == GET /upload/edit/:id
  # == GET /upload/edit/SELECT
  #
  # Initiate modification of an existing EMMA entry by prompting for metadata
  # changes and/or upload of a replacement file.
  #
  # If :id is "SELECT" then a menu of editable items is presented.
  #
  # @see UploadController#update
  # @see UploadWorkflow::Single::Edit::States#on_editing_entry
  #
  def edit
    __debug_route
    @item = (wf_single(event: :edit) unless show_menu?(@identifier))
  rescue => error
    flash_now_failure(error)
  end

  # == PUT   /upload/update/:id
  # == PATCH /upload/update/:id
  #
  # Finalize modification of an existing EMMA entry.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  # @raise [UploadWorkflow::SubmitError]
  #
  # @see UploadWorkflow::Single::Edit::States#on_modifying_entry
  #
  def update
    __debug_route
    __debug_request
    @item = wf_single(event: :submit)
    post_response(:ok, @item, redirect: upload_index_path)
  rescue SubmitError => error
    post_response(:conflict, error)
  rescue => error
    post_response(error)
  end

  # == GET /upload/delete/:id[?force=true&truncate=true&emergency=true]
  # == GET /upload/delete/SID[?...]
  # == GET /upload/delete/RANGE_LIST[?...]
  # == GET /upload/delete/SELECT[?...]
  #
  # Initiate removal of an existing EMMA entry along with its associated file.
  #
  # If :id is "SELECT" then a menu of deletable items is presented.
  #
  # Use :force to attempt to remove an item from the EMMA Unified Search index
  # even if a database record was not found.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  #
  # @see UploadController#destroy
  # @see UploadWorkflow::Single::Remove::States#on_removing_entry
  #
  def delete
    __debug_route
    @list = []
    unless show_menu?(@identifier)
      @list = wf_single(rec: :unset, data: @identifier, event: :remove)
    end
  rescue => error
    flash_now_failure(error)
  end

  # == DELETE /upload/destroy/:id[?force=true&truncate=true&emergency=true]
  # == DELETE /upload/destroy/SID[?...]
  # == DELETE /upload/destroy/RANGE_LIST[?...]
  #
  # Finalize removal of an existing EMMA entry.
  #
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  #
  # @see UploadWorkflow::Single::Remove::States#on_removed_entry
  #
  #--
  # noinspection RubyScope
  #++
  def destroy
    __debug_route
    back  = delete_select_upload_path
    rec   = :unset
    dat   = @identifier
    opt   = { start_state: :removing, event: :submit, variant: :remove }
    @list = wf_single(rec: rec, data: dat, **opt)
    failure(:file_id) unless @list.present?
    post_response(:found, @list, redirect: back)
  rescue SubmitError => error
    post_response(:conflict, error, redirect: back)
  rescue => error
    post_response(:not_found, error, redirect: back)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /upload/bulk
  #
  # Currently a non-functional placeholder.
  #
  def bulk_index
    __debug_route
  rescue => error
    flash_now_failure(error)
  end

  # == GET /upload/bulk_new[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Display a form prompting for a bulk upload file in either CSV or JSON
  # format containing an entry for each entry to submit.
  #
  # @see UploadController#bulk_create
  # @see UploadWorkflow::Bulk::Create::States#on_creating_entry
  #
  def bulk_new
    __debug_route
    wf_bulk(rec: :unset, data: :unset, event: :create)
  rescue => error
    flash_now_failure(error)
  end

  # == POST /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Create the specified Upload entries, download and store the associated
  # files, and post the new entries to the Federated Ingest API.
  #
  # @raise [Net::HTTPConflict]
  #
  # @see UploadWorkflow::Bulk::Create::States#on_submitting_entry
  #
  def bulk_create
    __debug_route
    __debug_request
    @list = wf_bulk(start_state: :creating, event: :submit, variant: :create)
    wf_check_partial_failure
    post_response(:ok, @list, xhr: false)
  rescue SubmitError => error
    post_response(:conflict, error, xhr: false)
  rescue => error
    post_response(error, xhr: false)
  end

  # == GET /upload/bulk_edit[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Display a form prompting for a bulk upload file in either CSV or JSON
  # format containing an entry for each entry to change.
  #
  # @see UploadController#bulk_update
  # @see UploadWorkflow::Bulk::Edit::States#on_editing_entry
  #
  def bulk_edit
    __debug_route
    wf_bulk(rec: :unset, data: :unset, event: :edit)
  rescue => error
    flash_now_failure(error)
  end

  # == PUT /upload/bulk[?source=FILE&batch=true|SIZE&prefix=STRING]
  #
  # Modify or create the specified Upload entries, download and store the
  # associated files (if changed), and post the new/modified entries to the
  # Federated Ingest API.
  #
  # @raise [Net::HTTPConflict]
  #
  # @see UploadWorkflow::Bulk::Edit::States#on_modifying_entry
  #
  def bulk_update
    __debug_route
    __debug_request
    @list = wf_bulk(start_state: :editing, event: :submit, variant: :edit)
    wf_check_partial_failure
    post_response(:ok, @list, xhr: false)
  rescue SubmitError => error
    post_response(:conflict, error, xhr: false)
  rescue => error
    post_response(error, xhr: false)
  end

  # == GET /upload/bulk_delete[?force=false]
  #
  # Specify entries to delete by :id, SID, or RANGE_LIST.
  #
  # @raise [Net::HTTPConflict]
  #
  # @see UploadController#bulk_destroy
  # @see UploadWorkflow::Bulk::Remove::States#on_removing_entry
  #
  def bulk_delete
    __debug_route
    @list = wf_bulk(event: :remove)
  rescue => error
    flash_now_failure(error)
  end

  # == DELETE /upload/bulk[?force=true]
  #
  # @raise [Net::HTTPConflict]
  #
  # @see UploadWorkflow::Bulk::Remove::States#on_removed_entry
  #
  def bulk_destroy
    __debug_route
    __debug_request
    @list = wf_bulk(start_state: :removing, event: :submit, variant: :remove)
    failure(:file_id) unless @list.present?
    wf_check_partial_failure
    post_response(:found, @list)
  rescue SubmitError => error
    post_response(:conflict, error, xhr: false)
  rescue => error
    post_response(error, xhr: false)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == POST /upload/renew
  #
  # Invoked to re-create a database entry that had been canceled.
  #
  def renew
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
  def reedit
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
  # @see UploadWorkflow::Single::States#on_canceled_entry
  # @see UploadWorkflow::Bulk::States#on_canceled_entry
  # @see cancelForm() in app/assets/javascripts/feature/file-upload.js
  #
  def cancel
    __debug_route
    @item = wf_single(event: :cancel)
    if request.get?
      redirect_to(params[:redirect] || upload_index_path)
    else
      post_response(:ok)
    end
  rescue => error
    if request.get?
      flash_now_failure(error)
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
  # @see UploadConcern#wf_single_check
  #
  def check
    __debug_route
    @list = wf_single_check
    respond_to do |format|
      format.html
      format.json { render_json(messages: @list) }
      format.xml  { render_xml( messages: @list) }
    end
  rescue => error
    flash_now_failure(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == POST /upload/endpoint
  #
  # Invoked from 'Uppy.XHRUpload'.
  #
  # @see UploadWorkflow::Single::Create::States#on_validating_entry
  # @see UploadWorkflow::Single::Edit::States#on_replacing_entry
  # @see UploadWorkflow::External#upload_file
  # @see app/assets/javascripts/feature/file-upload.js
  #
  def endpoint
    __debug_route
    __debug_request
    rec = @db_id || @identifier
    dat = { env: request.env }
    stat, hdrs, body = wf_single(rec: rec, data: dat, event: :upload)
    self.status = stat        if stat.present?
    self.headers.merge!(hdrs) if hdrs.present?
    self.response_body = body if body.present?
  rescue SubmitError => error
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
  # @raise [Net::HTTPBadRequest]
  # @raise [Net::HTTPNotFound]
  #
  # @see UploadConcern#get_record
  # @see Upload#download_url.
  #
  def download
    __debug_route
    @item = get_record(@identifier)
    @link = @item.download_url
    respond_to do |format|
      format.html { redirect_to(@link) }
      format.json { render_json download_values }
      format.xml  { render_xml  download_values }
    end
  end

  # == GET /retrieval?url=URL[&member=BS_ACCOUNT_ID]
  #
  # Retrieve a file from a member repository.
  #
  def retrieval
    __debug_route
    if ia_link?(@url)
      ia_download_response(@url)
    elsif bs_link?(@url)
      redirect_to bs_retrieval_path(url: @url, forUser: @member)
    else
      Log.error { "/retrieval can't handle #{@url.inspect}"}
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /upload/admin[?{deploy|deployment}={'production'|'staging'}]
  # == GET /upload/admin[?{repo|repository}={'emma'|'ia'}]
  #
  # Upload submission administration.
  #
  def admin
    __debug_route
    opt           = url_parameters
    @repo         = repositories(**opt)
    @deploy       = deployments(default: application_deployment, **opt)
    @object_table = get_object_table(@repo, @deploy, **opt)
  rescue => error
    flash_now_failure(error)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether URL parameters indicate that a menu should be shown rather
  # than operating on an explicit set of identifiers.
  #
  # @param [String, Array<String>, nil] id_params  Default: `@identifier`.
  #
  def show_menu?(id_params = nil)
    Array.wrap(id_params || @identifier).include?('SELECT')
  end

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # @param [Exception] error
  # @param [String]    fallback_location    Redirect fallback if not modal.
  #
  def show_search_failure(error, fallback_location)
    if modal?
      flash_now_failure(error)
    else
      flash_failure(error)
      redirect_back(fallback_location: fallback_location)
    end
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
    return unless @identifier && @identifier.match?(/[^[:alnum:]]/)
    redirect_to action: :index, selected: @identifier
  end

  # ===========================================================================
  # :section: SerializationConcern overrides
  # ===========================================================================

  protected

  # Response values for de-serializing the index page to JSON or XML.
  #
  # @param [Array<Upload>] list
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def index_values(list = @list)
    { entries: super(list) }
  end

  # Response values for de-serializing the show page to JSON or XML.
  #
  # @param [Upload, Hash] item
  #
  # @return [Hash{Symbol=>*}]
  #
  def show_values(item = @item, **)
    item = item.is_a?(Upload) ? item.attributes.symbolize_keys : item.dup
    data = item.extract!(:file_data).first&.last
    item[:file_data] = safe_json_parse(data)
    # noinspection RubyYardReturnMatch
    item
  end

  # Response values for de-serializing download information to JSON or XML.
  #
  # @param [String] url
  #
  # @return [Hash{Symbol=>String}]
  #
  def download_values(url = @link)
    { url: url }
  end

end

__loading_end(__FILE__)
